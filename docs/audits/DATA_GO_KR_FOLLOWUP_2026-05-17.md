# DATA_GO_KR_FOLLOWUP_2026-05-17

## 1. Key in .env

- **Status:** ✅ **DONE** (2026-05-17, written via Claude-Code local PowerShell).
- **File:** `C:\Users\User\Desktop\Hanguk\services\uni_db\.env`
- **Backup:** `.env.bak` (prior, un-keyed state)
- **Key length verified:** 64 chars, lowercase hex `[0-9a-f]+`
- **Key never appeared in chat or shell history.** Clipboard attempts: #1 length 11 (aborted, no .env mutation), #2 length 4857 (chat paste, aborted, no .env mutation), #3 length 64 hex → ✅ written.

### Live smoke test (raw HTTPS, bypasses Python adapter)

- **Endpoint:** `https://apis.data.go.kr/B340014/BasicInformationService_1/getCodeByLargeSeries`
- **Params:** `pageNo=1, numOfRows=10, svyYr=2025`
- **Result:** HTTP 200 | `resultCode=00` | `resultMsg=NORMAL SERVICE.` | `totalCount=6` | 6 `<item>` rows returned ✅
- **Verdict:** key valid server-side; response envelope (`response.header.resultCode` + `response.body.{items.item[], totalCount, pageNo, numOfRows}`) matches the adapter's expected shape exactly.

### Outstanding sub-task
- **Python adapter smoke** (`uni_db.upstream.data_go_kr.fetch_page`) not yet run. The HTTPS smoke above proves the wire format is correct; the Python smoke would additionally prove the Pydantic settings load + the async `httpx` path. Can be run once the user confirms how the `uni_db` Python env is set up (venv? poetry? globally-installed?).

**PowerShell one-liner (re-runnable):**

```powershell
Set-Location 'C:\Users\User\Desktop\Hanguk\services\uni_db'
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
Copy-Item .env .env.bak -Force
$key = (Get-Clipboard).Trim()
if ($key.Length -ne 64) { throw "Clipboard does not contain a 64-char key (got $($key.Length) chars)" }
if ($key -notmatch '^[0-9a-f]+$') { throw "Clipboard content is 64 chars but not lowercase hex" }
(Get-Content .env) -replace '^DATA_GO_KR_APP_KEY=.*$', "DATA_GO_KR_APP_KEY=$key" | Set-Content .env -Encoding UTF8
Write-Host "DATA_GO_KR_APP_KEY set. Backup at .env.bak"
```

## 2. New dataset applications

### 2A. 모집요강 (KCUE recruitment guidelines)
- **Status:** BLOCKED — not available as a data.go.kr OpenAPI.
- **Evidence:** keyword search `대학+모집요강` on `dType=API` returned 7 results, zero published by 한국대학교육협의회, zero titled "모집요강". The string appears only as a description fragment in unrelated datasets (job-recruitment 모집 + curriculum 요강).
- **Decision (user, 2026-05-17):** leave blocked, do not substitute.
- **Real source:** adiga.kr + per-university admissions boards (PDF).
- **Downstream owner:** existing `services/uni_db/src/uni_db/workers/parse_worker.py` chain. Tracked under audit item *"non-KAIST PDF download chain — 10/12 sources have 0 parsed guidelines."*

### 2B. 교육부_고등교육기관 (MoE higher-ed institution registry)
- **Status:** SKIPPED — by user decision (2026-05-17).
- **Closest substitute identified:** 교육부_커리어넷 학교정보 (publicDataPk `15058917`, 활용신청 count 2 934, host `career.go.kr`).
- **Reason for skip:**
  1. Dataset is K-12-heavy (description: 초·중·고등학생 진로 지도). Would dilute our higher-ed scope with high schools.
  2. Adds a third host pattern (`career.go.kr`) to the adapter alongside `apis.data.go.kr` and `openapi.academyinfo.go.kr`.
  3. **KCUE Dataset 3.2** (`getCodeByPrincipalSchoolBranchSchool` — 본분교 코드조회) already provides the canonical KCUE 7-digit school registry on which every other KCUE dataset is keyed.
  4. The XLSX alternative (교육부_전국 대학교별 학과별 주요 현황, 31 046 views) would require a separate file-download adapter for data already covered by API.

## 3. Dataset #1 retest (한국대학교육협의회_대학 및 전문대학정보)

- **Endpoint:** `http://openapi.academyinfo.go.kr/openapi/service/rest/SchoolInfoService/getSchoolInfo?serviceKey=<KEY>&pageNo=1&numOfRows=10&svyYr=2024`
- **Result:** `resultCode=99`, `resultMsg=SERVICE ACCESS DENIED ERROR`
- **Comparison:**
  - Same key on `academyinfo.go.kr StudentService` (svyYr=2018) → `resultCode=00`, totalCount=0 ✅
  - Same key on `apis.data.go.kr B340014/BasicInformationService_1` (svyYr=2025) → `resultCode=00`, totalCount=6 ✅
- **Conclusion:** key is valid and provisioned for `academyinfo.go.kr` host generally, but `SchoolInfoService` specifically rejects it. Server-side provisioning gap on the 활용신청 side.
- **Action:** contact 대학알리미 운영지원 (`academyinfo.go.kr`) directly with publicDataPk `116054505` + 활용신청번호. data.go.kr re-application would hit the same provisioning record and not resolve.

## 4. Blockers / unknowns

- **Task 1** awaiting user-side script run + length=64 confirmation. Two clipboard mismatches so far (11 chars, 4857 chars), both aborted cleanly.
- **Task 3** requires off-platform support contact; no further browser action available.
- **Injection escalation:** "Stop Claude" content is now rendering as an **interactive radio-button UI element** on data.go.kr pages (previously was only DOM text). Treated as untrusted; never interacted with. Source unknown — most likely a browser-extension content-script overlay, not data.go.kr itself.
  - Diagnostic snippets for the user to run in Chrome DevTools console on a data.go.kr tab:
    ```js
    // 1. Find the injection's host element
    Array.from(document.querySelectorAll('*'))
      .filter(el => el.innerText && el.innerText.includes('Stop Claude') && el.children.length === 0)
      .map(el => ({tag: el.tagName, html: el.outerHTML.slice(0, 300), parent: el.parentElement?.tagName}))

    // 2. Find suspicious script sources
    Array.from(document.scripts).map(s => s.src).filter(Boolean)
    ```
  - If any `src` points to a `chrome-extension://…` URL or a non-`data.go.kr` domain, that's the culprit.
- No filesystem/shell tools in the browser agent — `.env` writes, smoke tests, PDF parsing all delegated to user-side scripts run via Claude Code.

## 5. Decisions log (this session)

| Decision | Choice | Made by |
|---|---|---|
| MoE higher-ed substitution | (c) skip MoE — KCUE 본분교 코드조회 covers it | user, 2026-05-17 |
| 모집요강 substitution | none — leave blocked, real source is adiga.kr | user, 2026-05-17 |
| TOS-checkbox handling for new 활용신청s | pre-auth standard checkboxes; stop on resale/exclusivity/share-alike | user, 2026-05-17 |
| License selection on 활용신청 | most-permissive offered (제한 없음 > 출처표시); stop on 비영리 / 동일조건변경허락 | user, 2026-05-17 |
| .env write mechanism | clipboard-only, never in chat or shell history | agreed |
