# Google Play listing — draft

Developer: **Yasvar Labs** · App: **AI Explorer** · Package: `com.yasvarlabs.aiexplorer`
(package is permanent after the first upload)

All text below is a **draft**. Hindi and Telugu need the same native-speaker
review as the in-app text (docs/TRANSLATION_REVIEW.md).

## Store details

| Field | Value |
|---|---|
| App name (≤ 30) | AI Explorer |
| Category | Education |
| Contact email | _to be set: a Yasvar Labs support address_ |
| Website | _to be set_ |
| Privacy policy URL | _required before review; to be written and hosted_ |

**Short description (≤ 80 chars)**

- en: `Learn how AI works with Aiko — patterns, data and play for ages 5–7.`
- hi (draft): `आइको के साथ खेल-खेल में सीखो AI कैसे काम करता है — 5–7 साल के बच्चों के लिए।`
- te (draft): `ఐకోతో ఆడుతూ AI ఎలా పనిచేస్తుందో నేర్చుకో — 5–7 ఏళ్ల పిల్లల కోసం.`

**Full description (en draft)**

> Meet Aiko, a friendly robot who is learning how the world works — with your
> child's help. In short, spoken adventures children spot patterns, discover that
> examples are "data", and see how computers learn from them.
>
> • Made for ages 5–7, in English, हिन्दी and తెలుగు
> • Voice answers are understood on the device — no recordings leave the phone
> • No ads, no chat, no open internet, no generative AI
> • Parent area protected by a PIN
> • Pattern Forest is free; Music Lab and future worlds are part of Premium

## Families / content declarations (to confirm in Play Console)

- Target audience: **5 and under** and **6–8** (app is designed for 5–7).
- Ads: **none**.
- Teacher Approved: optional application after launch.

## Data safety (first pass — verify against the final build)

| Data | Collected? | Notes |
|---|---|---|
| Audio / voice | No | Speech recognition runs on-device (`onDevice: true`); audio and transcripts are never stored or sent |
| Purchase history | Yes, by RevenueCat | For app functionality (subscription status); not shared for ads |
| App user ID | Yes, by RevenueCat | Anonymous RevenueCat ID |
| Child's name / personal info | No | Profile holds only language and progress, stored on the device |
| Safety prompts | On-device count only | Timestamp count shown to the parent; no content stored or sent |
| Crash logs / analytics | No | None in this build |

Data is encrypted in transit (RevenueCat uses HTTPS). Users can delete all
local data by uninstalling or clearing app data.
