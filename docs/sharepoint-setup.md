# SharePoint setup for World Cup entries

This app stores player submissions in a **SharePoint List** on your IMW Microsoft 365 tenant. You do **not** need files on `C:\Git\2026 FIFA` — SharePoint is the shared database everyone can view and export.

A **minimal Power Automate flow** (3 steps) is the recommended HTTP gateway because GitHub Pages cannot write to SharePoint directly without user sign-in. The flow only receives the form POST and creates a list row — all data lives in SharePoint.

## Step 1 — Create the SharePoint List

1. Open your IMW SharePoint site (e.g. team site or communication site).
2. **New → List → Blank list**
3. Name: `World Cup 2026 Entries`
4. Add columns:

| Column | Type | Notes |
|--------|------|-------|
| Title | Single line (default) | Player name — mapped from flow |
| PlayerEmail | Single line of text | Optional |
| SubmittedAt | Date and time | |
| Phase | Choice | `groupStage`, `knockout` |
| EntryJson | Multiple lines of text | Full JSON backup |
| GroupA_1st … GroupL_4th | Single line of text | One column per slot (optional but easy to filter in Excel) |

> **Tip:** You can start with just `Title`, `PlayerEmail`, `SubmittedAt`, and `EntryJson`. Add group columns later if you want Excel-friendly views.

5. Share the list with EEC participants (Contribute) and organizers (Edit/Owner).

## Step 2 — Create the HTTP gateway flow (Power Automate)

1. [Power Automate](https://make.powerautomate.com) → **Create → Instant cloud flow**
2. Name: `World Cup 2026 - Save Entry to SharePoint`
3. Trigger: **When a HTTP request is received**
4. Click **Use sample payload to generate schema** and paste:

```json
{
  "playerName": "Jane Doe",
  "playerEmail": "jane.doe@imw.ca",
  "submittedAt": "2026-06-05T18:30:00.000Z",
  "phase": "groupStage",
  "entryJson": "{\"name\":\"Jane Doe\",\"groups\":{}}",
  "GroupA_1st": "MEX",
  "GroupA_2nd": "KOR",
  "GroupA_3rd": "RSA",
  "GroupA_4th": "CZE"
}
```

5. Add action: **Create item** (SharePoint connector)
   - Site Address: your IMW SharePoint site
   - List Name: `World Cup 2026 Entries`
   - Map fields:
     - **Title** → `playerName` from trigger
     - **PlayerEmail** → `playerEmail`
     - **SubmittedAt** → `submittedAt`
     - **Phase** → `phase`
     - **EntryJson** → `entryJson`
     - Map group columns if you created them (`GroupA_1st`, etc.)

6. (Optional) Add **Response** action → Status `200`, Body `{ "status": "ok" }`

7. **Save** the flow and copy the **HTTP POST URL** from the trigger.

## Step 3 — Configure the app

Edit `src/data/config.js`:

```javascript
sharepoint: {
  enabled: true,
  webhookUrl: 'PASTE_YOUR_HTTP_POST_URL_HERE',
  listName: 'World Cup 2026 Entries',
},
```

Commit and deploy. Players use **Submit to SharePoint** on the Group Stage tab.

## Viewing & exporting entries

- Open the SharePoint list in browser — sort/filter by player or date.
- **Export to Excel** from the list command bar for offline scoring.
- Organizers can sync results back into the app Admin tab for the in-app leaderboard.

## Why not a local file?

Power Automate cloud flows cannot write to `C:\Git\2026 FIFA` on your PC unless you install an **on-premises data gateway** and use the **File System** connector. SharePoint is simpler for an office pool: one URL, automatic backups, and permissions via Microsoft 365.

## Avoiding Power Automate entirely (advanced)

If IMW IT can register an **Azure AD app** with SharePoint permissions, the site could call the SharePoint REST API directly with Microsoft sign-in (MSAL). That removes Power Automate but requires IT setup. Contact IT if you prefer this route.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Submit button says URL not configured | Paste webhook URL in `config.js` and redeploy |
| Browser blocks request (CORS) | Flow still receives `text/plain` POST; add Response action; confirm trigger allows anonymous calls |
| Duplicate entries | Add a list view sorted by player; enforce one submission per person via honor system or IT Power Automate duplicate check |
| Need knockout phase later | Same list — `phase` column distinguishes group vs knockout submissions |

## Sample flow schema fields

The app POSTs this JSON shape:

```json
{
  "playerName": "string",
  "playerEmail": "string",
  "submittedAt": "ISO-8601 datetime",
  "phase": "groupStage",
  "groups": {
    "A": ["MEX", "KOR", "RSA", "CZE"],
    "B": ["...", "...", "...", "..."]
  },
  "entryJson": "stringified backup",
  "GroupA_1st": "MEX",
  "GroupA_2nd": "KOR"
}
```

Group columns `GroupB_1st` through `GroupL_4th` are included when those columns exist in the list.
