"""Translation worker — fans out from new Korean rows to target languages.

Plan §P.3 / §C.15. Picks rows where (entity, field) lacks a translation
in the requested language and writes the output to `translations`.

Phase 0: writes are real; the providers under translate/* return mocks
so no paid tokens are spent.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Mapping
from uuid import UUID

import asyncpg

from ..translate.glossary import GlossaryCache
from ..translate.models import TargetLang
from ..translate.pipeline import translate

log = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class TranslationJob:
    entity_type: str
    entity_id: UUID
    field_name: str
    source_text_ko: str
    target_lang: TargetLang
    is_label: bool


PENDING_SQL = """
select 'institutions'              as entity_type,
       i.id                        as entity_id,
       'name_ko'                   as field_name,
       i.name_ko                   as source_text_ko,
       $1::text                    as target_lang,
       true                        as is_label
  from public.institutions i
  left join public.translations t
    on t.entity_type = 'institutions'
   and t.entity_id   = i.id
   and t.field_name  = 'name_ko'
   and t.lang        = $1::text
 where t.id is null and i.name_ko is not null
 limit $2
"""


async def fetch_pending_jobs(
    conn: asyncpg.Connection,
    *,
    target_lang: TargetLang,
    limit: int = 50,
) -> list[TranslationJob]:
    rows = await conn.fetch(PENDING_SQL, target_lang, limit)
    return [
        TranslationJob(
            entity_type=r["entity_type"],
            entity_id=r["entity_id"],
            field_name=r["field_name"],
            source_text_ko=r["source_text_ko"],
            target_lang=r["target_lang"],
            is_label=r["is_label"],
        )
        for r in rows
    ]


async def run_jobs(
    conn: asyncpg.Connection,
    jobs: list[TranslationJob],
    *,
    glossary: GlossaryCache,
) -> int:
    written = 0
    for job in jobs:
        result = translate(
            source_text_ko=job.source_text_ko,
            target_lang=job.target_lang,
            glossary=glossary,
            is_label=job.is_label,
        )
        await conn.execute(
            """
            insert into public.translations (
              entity_type, entity_id, field_name, lang,
              text_value, source_lang, provider, confidence,
              back_trans_distance, is_machine
            ) values ($1,$2,$3,$4,$5,$6,$7,$8,$9,true)
            on conflict (entity_type, entity_id, field_name, lang) do update
              set text_value         = excluded.text_value,
                  provider           = excluded.provider,
                  confidence         = excluded.confidence,
                  back_trans_distance= excluded.back_trans_distance,
                  is_machine         = true,
                  created_at         = now()
            """,
            job.entity_type,
            job.entity_id,
            job.field_name,
            job.target_lang,
            result.text_value,
            "ko",
            result.provider,
            result.confidence,
            result.back_trans_distance,
        )
        written += 1
    return written


async def load_glossary(
    conn: asyncpg.Connection,
    *,
    target_lang: TargetLang,
) -> Mapping[tuple[str, TargetLang], object]:
    from ..translate.glossary import GlossaryHit

    rows = await conn.fetch(
        """
        select term_ko, term_value, category
          from public.term_glossary
         where term_lang = $1 and authoritative = true
        """,
        target_lang,
    )
    return {
        (r["term_ko"], target_lang): GlossaryHit(
            term_ko=r["term_ko"],
            term_value=r["term_value"],
            category=r["category"],
        )
        for r in rows
    }
