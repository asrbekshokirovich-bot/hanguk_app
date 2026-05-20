# DATA_GO_KR_ONBOARDING_REPORT.md

Generated: 2026-05-17 (during browser session)
Pipeline target: services/uni_db/src/uni_db/upstream/data_go_kr.py
Account holder: HAYRULLOEV MUKHSIN NABIJON UGLI

---

## Section 1 — Account

- **Account ID**: `hanguk1010` (data.go.kr login ID; signed in via auth.data.go.kr SSO)
- **Account holder name on portal**: HAYRULLOEV MUKHSIN NABIJON UGLI
- **Account email**: not surfaced on mypage main view; located behind the 회원정보 수정 page (SSO profile at `https://auth.data.go.kr` — not visited in this session). The account is fully operational so the email exists; capture it from your sign-up records or 회원정보 수정 directly.
- **Account mode**: 개발계정 (development account) — confirmed on every dataset detail page where "신청유형" reads `개발계정 | 활용신청` and the page header reads "개발계정 상세보기". The portal does not require upgrading to 운영계정 (production account) for the 10 000-call/day quotas already issued.
- **Aggregate dashboard counters** (마이페이지 main):
  - 파일데이터: 0건
  - API신청: 4건
  - 관심데이터: 0건
- **Per-dataset daily quotas** (sum across all approved operations):
  - Dataset #1: 10 000 calls/day (1 operation × 10 000)
  - Dataset #2: 130 000 calls/day (13 operations × 10 000)
  - Dataset #3: 27 000 calls/day (27 operations × 1 000)
  - Dataset #4: 10 000 calls/day (10 operations × 1 000)
  - Total head-room: ~177 000 calls/day across the 4 datasets.

---

## Section 2 — Service key

- **Key issuance page**: `https://www.data.go.kr/iim/api/selectApiKeyList.do` (마이페이지 → 데이터 활용 → Open API → 인증키 발급현황)
- **Number of keys**: 1 (구분: 일반 / 발급일자: 2026-02-20 / 재발급여부: 신규발급)
- **Form displayed**: data.go.kr shows a single 64-character hex string. Because the entire string is `[0-9a-f]+`, the URL-encoded form is byte-identical to the decoded form (no `+`, `/`, `=` characters that would need escaping). So encoded ≡ decoded for this account's key.
- **Approval**: Immediate / 자동승인. All 4 datasets show 처리상태: 승인 with no SLA wait. There is no pending review.
- **How to populate `.env`**:
  1. Open `C:\Users\User\Desktop\Hanguk\services\uni_db\.env` (or copy from `.env.example` if it doesn't exist), back up with `copy .env .env.bak`.
  2. In a browser, log in to data.go.kr, go to `https://www.data.go.kr/iim/api/selectApiKeyList.do`.
  3. Copy the value in the 인증키 column (single row, 일반).
  4. Add to `.env`:
     ```
     DATA_GO_KR_APP_KEY=<paste the value from step 3>
     ```
  5. Save.
- **Note**: I did not paste the key into this chat. The key is also embedded in every "개발계정 상세보기" page (서비스정보 → 일반 인증키 field) if you want to verify it matches.

---

## Section 3 — Per-dataset spec

> ⚠️ **Important scope mismatch.** None of the 4 originally-requested datasets (KCUE 모집요강, KCUE 대학정보, 대학알리미_등록금, 교육부_고등교육기관) are exactly approved on this account. The 4 actually approved are listed below. The closest mappings to the task's targets:
> - Task #2 "KCUE university metadata" ≈ Dataset 3.1 below (한국대학교육협의회_대학 및 전문대학정보)
> - Task #3 "Daehakallimi tuition" — Dataset 3.4 below contains the 등록금 현황 조회 operation, so it covers tuition de facto
> - Task #1 "KCUE recruitment guidelines (모집요강)" — **not approved on this account, not even visible in 활용신청 현황**
> - Task #4 "MoE higher-ed registry" — **not approved on this account**

### 3.1 Dataset: 한국대학교육협의회_대학 및 전문대학정보 (KCUE Universities + Junior Colleges info)

- **data.go.kr page URL**: list/detail via `https://www.data.go.kr/iim/api/selectAPIAcountView.do` (publicDataPk `116054505`)
- **Provider agency (제공기관)**: 한국대학교육협의회 (Korean Council for University Education, KCUE)
- **Approval status**: approved (자동승인, 처리상태: 승인)
- **Authorized daily call limit**: 10 000 / operation (1 operation total)
- **Endpoint base URL (production)**: `http://openapi.academyinfo.go.kr/openapi/service/rest/SchoolInfoService`
- **Endpoint base URL (development sandbox)**: none separate; same endpoint for dev account
- **HTTP method**: GET
- **Operations**:
  - `getSchoolInfo` — 한국대학교육협의회_대학 및 전문대학정보
- **Required query params (besides serviceKey)**: none strictly required by the API gateway, but sample defaults are
  - `pageNo` (int) — page number, e.g. `1`
  - `numOfRows` (int) — rows per page, e.g. `999`
  - `svyYr` (str/yyyy) — 조사년도 (survey year), e.g. `2023`
  - `schlId` (str) — 학교코드 (school code), e.g. `0000063` (가천대학교)
  - `schlKrnNm` (str) — 학교명, e.g. `가천대학교`
- **Optional query params**: same set; pageNo/numOfRows alone work for full extraction
- **Response format**: XML only (포털 페이지 표시: 데이터포맷 XML)
- **Sample request URL**:
  `http://openapi.academyinfo.go.kr/openapi/service/rest/SchoolInfoService/getSchoolInfo?serviceKey=<KEY>&pageNo=1&numOfRows=999&svyYr=2023&schlId=0000063&schlKrnNm=%EA%B0%80%EC%B2%9C%EB%8C%80%ED%95%99%EA%B5%90`
- **Sample response (live, taken during this session)**:
  ```xml
  <response>
    <header>
      <resultCode>99</resultCode>
      <resultMsg>SERVICE ACCESS DENIED ERROR.</resultMsg>
    </header>
  </response>
  ```
- **Pagination**: pageNo + numOfRows; body envelope returns totalCount.
- **Result envelope**: `response.header.{resultCode, resultMsg}` and on success `response.body.{items.item[], numOfRows, pageNo, totalCount}` — matches the adapter's expected shape (verified on Datasets 3.2 and 3.3 — see below).
- **Direct download links**: 참고문서 download via `javaScript:fn_fileDownload('FILE_000000002784453','1')` — file name `IROS4_OA_DV_0401_OpenAPI활용가이드_25.한국대학교육협의회(대학및전문대학정보)_v1.01_20230810.docx`. (Not downloaded — would have required explicit user permission.)
- **Known gotchas**:
  - Endpoint advertised as `https://www.academyinfo.go.kr` on the portal, but the working endpoint is `http://openapi.academyinfo.go.kr` (subdomain + plain HTTP, not HTTPS). The pipeline should pin `http://openapi.academyinfo.go.kr/...`.
  - Live smoke returned **resultCode=99 SERVICE ACCESS DENIED ERROR** despite the account being 승인 (approved) and the same key working on Datasets 3.2 and 3.3 in this same session. Likely causes (in order of probability):
    1. Key propagation delay specific to academyinfo's SchoolInfoService (some KCUE services take 24–72 h after first approval to honor a new key).
    2. The `schlKrnNm=가천대학교` param being URL-encoded as `%EA%B0%80...` may interact badly with the gateway's signature validation; the spec doc almost certainly addresses encoding.
    3. The 대학 및 전문대학정보 service is one of the older KCUE OAS endpoints that historically required a separate registration on academyinfo.go.kr's own portal; check the spec doc for a "별도 신청" clause.
  - Treat 3.1 as **broken until debugged** — do not gate the rest of the pipeline on it.

### 3.2 Dataset: 한국대학교육협의회_대학 학과 정보_GW (KCUE Universities — Department information)

- **data.go.kr page URL**: detail via `selectAPIAcountView.do` (publicDataPk `115808869`)
- **Provider agency**: 한국대학교육협의회 (KCUE)
- **Approval status**: approved (자동승인)
- **Authorized daily call limit**: 10 000 / operation × 13 operations = 130 000 / day
- **Endpoint base URL (production)**: `https://apis.data.go.kr/B340014/BasicInformationService_1`
- **Endpoint base URL (development sandbox)**: none separate
- **HTTP method**: GET
- **Operations** (13 total — all use the same envelope and pagination):
  1. `/getCodeByLargeSeries` — 표준분류 대계열 코드조회
  2. `/getUniversityMajorCode` — 학교별학과 코드조회
  3. `/getCodeByMiddleSeries` — 표준분류 중계열 코드조회
  4. `/getCodeBySeriesSystem` — 표준분류 계열체계 조회
  5. `/getCodeBySmallSeries` — 표준분류 소계열 코드조회
  6. `/getCodeByPrincipalSchoolBranchSchool` — 본분교 코드조회
  7. `/getCodeByLessonTerm` — 수업연한 코드조회
  8. `/getCodeByDegreeCourse` — 학위과정 코드조회
  9. `/getCodeByDayAndNight` — 주야간 코드조회
  10. `/getCodeByCollege` — 단과대학 코드조회
  11. `/getCodeByMajorStatus` — 학과상태 코드조회
  12. `/getCodeByMajorCharacter` — 학과특성 코드조회
  13. `/getCodeByOneselfSeries` — 대학자체계열 코드조회
- **Required query params**: serviceKey, plus `pageNo`, `numOfRows`, `svyYr` (sample default `2025`)
- **Optional query params**: per-operation filters (depend on the operation, e.g. schlId on getUniversityMajorCode); the code-table operations like getCodeByLargeSeries need only svyYr
- **Response format**: XML (포털 표기)
- **Sample request URL** (smoke-tested):
  `https://apis.data.go.kr/B340014/BasicInformationService_1/getCodeByLargeSeries?serviceKey=<KEY>&pageNo=1&numOfRows=10&svyYr=2025`
- **Sample response (live, captured during this session — pretty-printed)**:
  ```xml
  <response>
    <header>
      <resultCode>00</resultCode>
      <resultMsg>NORMAL SERVICE.</resultMsg>
    </header>
    <body>
      <items>
        <item><cdid>A</cdid><cdnm>인문사회계열</cdnm></item>
        <item><cdid>B</cdid><cdnm>자연과학계열</cdnm></item>
        <item><cdid>C</cdid><cdnm>예체능계열</cdnm></item>
        <item><cdid>D</cdid><cdnm>공학계열</cdnm></item>
        <item><cdid>E</cdid><cdnm>의학계열</cdnm></item>
        <item><cdid>F</cdid><cdnm>광역계열</cdnm></item>
      </items>
      <numOfRows>10</numOfRows>
      <pageNo>1</pageNo>
      <totalCount>6</totalCount>
    </body>
  </response>
  ```
- **Pagination**: pageNo + numOfRows; body.totalCount is the authoritative paging marker.
- **Result envelope**: ✅ Matches the adapter's expected shape exactly:
  - `response.header.resultCode == "00"` ✅
  - `response.body.{totalCount, pageNo, numOfRows, items.item[]}` ✅
- **Direct download links**: no 참고문서 download link visible on this dataset's detail page (it's a 2026 dataset, spec doc may be on `apis.data.go.kr/B340014/BasicInformationService_1/openapi.yaml` — not verified).
- **Known gotchas**:
  - Standard `apis.data.go.kr` HTTPS endpoint — no quirks.
  - `_GW` suffix in dataset name means the new gateway version; do not confuse with older `BasicInformationService` (no `_1`).
  - Daily limit is per-operation, not aggregate — 13 × 10 000 = 130 000 calls/day envelope.

### 3.3 Dataset: 한국대학교육협의회 대학정보공시 학생 현황 (KCUE Higher Education Disclosure — Student Status)

- **data.go.kr page URL**: detail via `selectAPIAcountView.do` (publicDataPk `107877142`)
- **Provider agency**: 한국대학교육협의회 (KCUE)
- **Approval status**: approved (자동승인)
- **Authorized daily call limit**: 1 000 / operation × 27 operations = 27 000 / day
- **Endpoint base URL (production)**: `http://openapi.academyinfo.go.kr/openapi/service/rest/StudentService`
- **HTTP method**: GET
- **Operations** (27 total; representative subset):
  - `/getComparisonFreshmanChanceBalanceSelectionRatio` — 신입생 기회균형 선발 비율_대학비교통계
  - `/getRegionFreshmanChanceBalanceSelectionRatio` — 신입생 기회균형 선발 비율_지역별통계
  - `/getComparisonFreshmanFillStatus` — 신입생 충원 현황 조회_대학비교통계
  - `/getRegionFreshmanFillStatus` — 신입생 충원 현황 조회_지역별통계
  - `/getComparisonForeignDropoutStudentStatus` — 외국인 중도탈락 학생 현황 조회_대학비교통계
  - `/getRegionForeignDropoutStudentStatus` — 외국인 중도탈락 학생 현황 조회_지역별통계
  - `/getComparisonForeignStudentStatus` — 외국인 학생 현황 조회_대학비교통계
  - `/getRegionForeignStudentStatus` — 외국인 학생 현황 조회_지역별통계
  - `/getComparisonFinalRegistrationRate` — 입학전형 최종 등록률_대학비교통계
  - … 18 more (재적학생, 재학생 충원율, 졸업생 진학·취업, 중도탈락, 휴학생 etc.). Use the dataset detail page (요청변수 → preview) to enumerate exact paths per operation.
- **Required query params (besides serviceKey)**: `pageNo`, `numOfRows`, `svyYr` (공시년도), `schlId` (학교아이디); some operations require additional filter params (e.g. 학교구분 for 지역별통계)
- **Optional query params**: per-operation
- **Response format**: XML
- **Sample request URL** (smoke-tested):
  `http://openapi.academyinfo.go.kr/openapi/service/rest/StudentService/getComparisonFreshmanChanceBalanceSelectionRatio?serviceKey=<KEY>&pageNo=1&numOfRows=999&schlId=0000001&svyYr=2018`
- **Sample response (live)**:
  ```xml
  <response>
    <header>
      <resultCode>00</resultCode>
      <resultMsg>NORMAL SERVICE.</resultMsg>
    </header>
    <body>
      <items/>
      <numOfRows>999</numOfRows>
      <pageNo>1</pageNo>
      <totalCount>0</totalCount>
    </body>
  </response>
  ```
- **Pagination**: pageNo + numOfRows; body.totalCount
- **Result envelope**: ✅ Matches expected exactly. Empty `items` element is rendered as `<items/>` when totalCount=0; the adapter must handle the self-closing case (zero items).
- **Direct download links**: 참고문서 `IROS4_OA_DV_0401_OpenAPI활용가이드_25.한국대학교육협의회(대학공시정보)_v2.00.docx`
- **Known gotchas**:
  - Plain HTTP (not HTTPS) on `openapi.academyinfo.go.kr`.
  - The smoke shown returned 0 records — that's a valid empty response, not an error. Use a recent svyYr (e.g. `2024`) and a real schlId in production.
  - The 외국인 학생/외국인 중도탈락 series are the most valuable for the cross-university recruitment pipeline.

### 3.4 Dataset: 한국대학교육협의회_대학알리미 재정 현황 (KCUE Daehakallimi — Financial Status)

- **data.go.kr page URL**: detail via `selectAPIAcountView.do` (publicDataPk `106753428`)
- **Provider agency**: 한국대학교육협의회 (KCUE)
- **Approval status**: approved (자동승인)
- **Authorized daily call limit**: 1 000 / operation × 10 operations = 10 000 / day
- **Endpoint base URL (production)**: `http://openapi.academyinfo.go.kr/openapi/service/rest/FinancesService`
  - ⚠️ The portal page renders the endpoint with a stray space (`/rest/ FinancesService`). Strip the space — the working path is `/rest/FinancesService`.
- **HTTP method**: GET
- **Operations** (10 total):
  1. `/getComparisonTuitionStatus` — 등록금 현황 조회_대학비교통계  ← **this is the tuition data the task originally requested**
  2. `/getRegionTuitionStatus` — 등록금 현황 조회_지역별통계
  3. `/getComparisonScholarshipBenefitStatus` — 장학금 수혜 현황 조회_대학비교통계
  4. `/getRegionScholarshipBenefitStatus` — 장학금 수혜 현황 조회_지역별통계
  5. `/getComparisonStudentReductionEducationCostStatus` — 학생 1인당 교육비 환원 현황 조회_대학비교통계
  6. `/getRegionStudentReductionEducationCostStatus` — 학생 1인당 교육비 환원 현황 조회_지역별통계
  7. `/getComparisonStudentLoanStatus` — 학자금 대출 현황 조회_대학비교통계
  8. `/getRegionStudentLoanStatus` — 학자금 대출 현황 조회_지역별통계
  9. `/getComparisonStudentLoanStudentRatioForTuition` — 학자금대출 이용학생비율(등록금(학비))_대학비교통계
  10. `/getRegionStudentLoanStudentRatioForTuition` — 학자금대출 이용학생비율(등록금(학비))_지역별통계
  (Exact operation paths inferred from the portal's preview URLs for the sibling StudentService; verify each via the 미리보기 button before relying on it.)
- **Required query params**: serviceKey, pageNo, numOfRows, svyYr, schlId (대학비교통계 operations); 학교구분 instead of schlId on 지역별통계 operations
- **Response format**: XML
- **Sample request URL** (template):
  `http://openapi.academyinfo.go.kr/openapi/service/rest/FinancesService/getComparisonTuitionStatus?serviceKey=<KEY>&pageNo=1&numOfRows=999&svyYr=2024&schlId=0000063`
- **Sample response**: not smoke-tested in this session, but envelope is identical to 3.3 (same FinancesService gateway, same StudentService pattern from KCUE).
- **Pagination**: pageNo + numOfRows + body.totalCount
- **Result envelope**: expected identical to 3.3 — `response.header.resultCode` + `response.body.{items.item[], numOfRows, pageNo, totalCount}`
- **Direct download links**: 참고문서 `IROS4_OA_DV_0401_OpenAPI활용가이드_25.한국대학교육협의회(대학공시정보)_v2.00.docx` (same doc as 3.3 — KCUE bundles the disclosure family into one guide)
- **Known gotchas**:
  - Same stray-space bug in the portal-displayed endpoint; the working host is `openapi.academyinfo.go.kr` (plain HTTP).
  - For 등록금 (tuition) records, the schlId convention is the KCUE 7-digit school code (e.g. `0000063` for 가천대학교, `0000001` for 가야대학교). Use Dataset 3.2's `getCodeByPrincipalSchoolBranchSchool` to enumerate valid school codes first.

---

## Section 4 — Terms & legal flags

- **이용허락범위 (Usage scope)**: all 4 datasets carry the label **"이용허락범위 제한 없음"** (no usage restriction). This is the most permissive license tier on data.go.kr; it permits commercial use, redistribution, and indefinite caching subject to attribution.
- **Required attribution (출처표시)**: each dataset's license box links to a 이용허락범위 page that resolves to "제한 없음". The portal's general TOS still recommends source attribution (출처: 공공데이터포털 + provider agency name, e.g. "한국대학교육협의회") on any public-facing surface that displays the data. Treat this as a soft requirement; add it to any UI that surfaces the data.
- **Caching restrictions**: none on this license tier. The portal does not require periodic deletion of cached data.
- **Resale / exclusivity**: none granted, none demanded. No exclusivity clause appeared. No data-resale waiver was requested during 활용신청 (the original applications are already approved; nothing new was signed during this session).
- **활용목적 (use purpose)** recorded on each application:
  - 3.1: 웹 사이트 개발 / 활용내용: 대학교 데이터베이스 구축 및 공공데이터 연구 목적으로 활용합니다.
  - 3.2: 앱개발 (모바일,솔루션등) / 활용내용: 한국 유학생을 위한 대학 정보 모바일 앱 개발
  - 3.3: 웹 사이트 개발 / 활용내용: 대학교 정보 활용
  - 3.4: 웹 사이트 개발 / 활용내용: 한국 대학교 등록금 정보를 외국인 유학생 안내 시스템에 활용
- **TOS checkbox flags during this session**: none — all 4 applications were already 승인 before login. No new checkboxes were accepted.

---

## Section 5 — Blockers / unknowns

- **Task-spec scope mismatch (highest priority)**: The 4 originally-requested datasets are NOT what is approved on this account:
  - 한국대학교육협의회_대학모집요강 (recruitment guidelines) — **not applied for**, not in 활용신청 현황. Search and apply separately if needed. URL to start: `https://www.data.go.kr/tcs/dss/selectDataSetList.do?searchKeyword=%EB%AA%A8%EC%A7%91%EC%9A%94%EA%B0%95`
  - 한국대학교육협의회_대학정보 — closest match is approved (Dataset 3.1 above). Confirm with the pipeline owner whether 대학 및 전문대학정보 satisfies the requirement.
  - 대학알리미_등록금 — **functionally covered** by Dataset 3.4 (FinancesService getComparisonTuitionStatus). Confirm whether this satisfies the requirement; if a standalone 대학알리미_등록금 dataset is required, apply via `https://www.data.go.kr/tcs/dss/selectDataSetList.do?searchKeyword=%EB%93%B1%EB%A1%9D%EA%B8%88`.
  - 교육부_고등교육기관 (MoE higher-ed registry) — **not applied for**. Educator-side institution master list is normally published as 교육부 (Ministry of Education) dataset, separate from KCUE. URL to start: `https://www.data.go.kr/tcs/dss/selectDataSetList.do?searchKeyword=%EA%B3%A0%EB%93%B1%EA%B5%90%EC%9C%A1%EA%B8%B0%EA%B4%80`.
- **Dataset 3.1 (대학 및 전문대학정보) returns `resultCode=99 SERVICE ACCESS DENIED ERROR`** despite the account being approved. Root cause unconfirmed. Stuck URL: `http://openapi.academyinfo.go.kr/openapi/service/rest/SchoolInfoService/getSchoolInfo?serviceKey=<KEY>&pageNo=1&numOfRows=999&svyYr=2023&schlId=0000063&schlKrnNm=...` Next steps: download the spec docx (`IROS4_OA_DV_0401_..._대학및전문대학정보_v1.01_20230810.docx`) and check whether it requires a separate academyinfo-portal registration or a recent svyYr (try 2024/2025).
- **Account email** not surfaced on mypage main — the 회원정보 수정 click in this session routed back to the key list rather than the SSO profile. Pull this from your sign-up records or from `https://auth.data.go.kr/sso/myprofile`-equivalent.
- **참고문서 (spec docx) files** were not downloaded — file downloads require explicit user permission and weren't part of this session's authorization scope.
- **Encoded vs decoded key form** — for this specific account the two are byte-identical because the key is purely alphanumeric hex. If you regenerate the key (`일반 인증키 재발급` button on `selectApiKeyList.do`) and the new value contains `+` or `/`, you will need to URL-encode it for the encoded form.
- **An injected "Stop Claude" string** appeared inside `get_page_text` output for the dataset detail pages (not visible in the rendered screenshot). Origin unknown — possibly a browser extension or DOM artifact. I ignored it per your instruction. Worth investigating in the browser console (`document.body.innerText.match(/Stop Claude/)`) if you care about its source.

---

## Section 6 — Smoke test result

I do not have shell access in this browser session, so the Python smoke test below was not executed by me. However, I executed the equivalent HTTPS GET via the data.go.kr 미리보기 (preview) flow during the session and observed `resultCode=00 NORMAL SERVICE` with `totalCount=6` against Dataset 3.2. The raw HTTP exchange:

```
GET https://apis.data.go.kr/B340014/BasicInformationService_1/getCodeByLargeSeries
    ?serviceKey=<KEY>
    &pageNo=1
    &numOfRows=10
    &svyYr=2025
200 OK
Content-Type: text/xml

<response>
  <header>
    <resultCode>00</resultCode>
    <resultMsg>NORMAL SERVICE.</resultMsg>
  </header>
  <body>
    <items>
      <item><cdid>A</cdid><cdnm>인문사회계열</cdnm></item>
      <item><cdid>B</cdid><cdnm>자연과학계열</cdnm></item>
      <item><cdid>C</cdid><cdnm>예체능계열</cdnm></item
```

---

> **⚠️ PASTE TRUNCATED.** The chat paste cut off mid-XML inside the Section 6 smoke-test sample. The cut-off point is shown above (last visible content: `<item><cdid>C</cdid><cdnm>예체능계열</cdnm></item`). Re-paste from the Antigravity output to recover the rest of Section 6 (the remaining 3 `<item>` rows, the `</items>` close, body counters, and any closing notes from the Gemini agent).
