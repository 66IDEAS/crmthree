#!/usr/bin/env bash
# Seeds a freshly applied database with demo users and records through the running app,
# which doubles as a smoke test of the whole stack. Requires the dev server on :5173.
set -euo pipefail
BASE="${1:-http://localhost:5173}"
J='Content-Type: application/json'
CK=$(mktemp); CK2=$(mktemp); trap 'rm -f "$CK" "$CK2"' exit

curl -sf -X POST "$BASE/api/users" -H "$J" \
  -d '{"email":"ada@example.com","password":"correct-horse-battery","firstName":"Ada","lastName":"Admin"}' >/dev/null
curl -sf -c "$CK" -X POST "$BASE/api/auth/sign-in/email" -H "$J" \
  -d '{"email":"ada@example.com","password":"correct-horse-battery"}' >/dev/null
curl -sf -b "$CK" -X POST "$BASE/api/users" -H "$J" \
  -d '{"email":"sam@example.com","password":"another-good-password","firstName":"Sam","lastName":"Sales","roleName":"User"}' >/dev/null
curl -sf -c "$CK2" -X POST "$BASE/api/auth/sign-in/email" -H "$J" \
  -d '{"email":"sam@example.com","password":"another-good-password"}' >/dev/null

ADA=$(curl -sf -b "$CK" "$BASE/api/me" | python3 -c "import sys,json;print(json.load(sys.stdin)['profile']['id'])")
SAM=$(curl -sf -b "$CK2" "$BASE/api/me" | python3 -c "import sys,json;print(json.load(sys.stdin)['profile']['id'])")

mk() { curl -sf -b "$CK" -X POST "$BASE/api/v1/$1" -H "$J" -d "$2" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])"; }

ACC=$(mk Account "{\"name1\":\"Acme Industries\",\"city\":\"Berlin\",\"country\":\"DE\",\"owner_id\":\"$ADA\",\"industry_description\":\"Manufacturing\"}")
ACC2=$(mk Account "{\"name1\":\"Globex GmbH\",\"city\":\"Hamburg\",\"country\":\"DE\",\"owner_id\":\"$SAM\"}")
CON=$(mk Contact "{\"first_name\":\"Grace\",\"last_name\":\"Hopper\",\"email\":\"grace@acme.example.com\",\"account_id\":\"$ACC\",\"owner_id\":\"$ADA\"}")
S1=$(mk PipelineStage '{"name":"Qualification","sort_order":1,"probability":10}')
S2=$(mk PipelineStage '{"name":"Proposal","sort_order":2,"probability":50}')
OPP=$(mk Opportunity "{\"name\":\"Acme expansion\",\"account_id\":\"$ACC\",\"stage_id\":\"$S1\",\"owner_id\":\"$SAM\",\"amount\":120000,\"currency\":\"EUR\"}")
mk DealRoom "{\"name\":\"Acme expansion room\",\"opportunity_id\":\"$OPP\",\"owner_id\":\"$SAM\",\"status\":\"Active\"}" >/dev/null
mk Lead "{\"first_name\":\"Ada\",\"last_name\":\"Lovelace\",\"company\":\"Analytical Ltd\",\"status\":\"New\",\"owner_id\":\"$SAM\"}" >/dev/null
TSTAT=$(mk TicketStatus '{"name":"Open","sort_order":1}')
mk Ticket "{\"subject\":\"Printer on fire\",\"priority\":\"High\",\"status_id\":\"$TSTAT\",\"owner_id\":\"$ADA\",\"assigned_to\":\"$SAM\",\"account_id\":\"$ACC\"}" >/dev/null
# Move the deal forward so a DealStageChange notification lands with Sam too.
curl -sf -b "$CK" -X PUT "$BASE/api/v1/Opportunity/$OPP" -H "$J" -d "{\"stage_id\":\"$S2\"}" >/dev/null

echo "seeded: 2 users, 2 accounts, contact, 2 stages, opportunity, deal room, lead, ticket"
echo "ada@example.com / correct-horse-battery (Admin)"
echo "sam@example.com / another-good-password (User)"
