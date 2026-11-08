// Check district Skyward OneRoster access from your own terminal before deploying.
//
//   cd firebase/functions
//   npm run skyward:probe -- <your student number>
//
// Reads SKYWARD_* values from firebase/functions/.env (or the environment),
// prints what the app would sync, and never prints the key or secret.
import * as fs from "fs";
import * as path from "path";
import { OneRosterClient, configFromEnv } from "../oneroster";

function loadDotEnv() {
  const file = path.join(__dirname, "..", "..", ".env");
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
}

async function main() {
  loadDotEnv();
  const student = process.argv[2];
  if (!student) {
    console.error("usage: npm run skyward:probe -- <student number>");
    process.exit(2);
  }
  const cfg = configFromEnv();
  if (!cfg) {
    console.error("SKYWARD_API_BASE is not set in firebase/functions/.env");
    process.exit(2);
  }
  console.log(`OneRoster base: ${cfg.baseUrl}`);
  console.log(`Auth: ${cfg.clientId ? "OAuth2 client credentials" : cfg.apiKey ? "static bearer key" : "none"}`);

  const out = await new OneRosterClient(cfg).fetchStudentData(student, { expectedEmail: null });
  console.log(`\nSchedule (${out.periods.length} classes):`);
  for (const p of out.periods) {
    console.log(`  P${p.period}  ${p.class_name}  room ${p.room ?? "?"}  ${p.teacher ?? ""}`);
  }
  console.log(`\nGrades (${out.grades.length}):`);
  if (!out.grades.length) console.log("  none (gradebook service not granted, or no marks posted yet)");
  for (const g of out.grades) {
    console.log(`  ${g.course}: ${g.grade}${g.percent != null ? ` (${g.percent}%)` : ""}  ${g.term}`);
  }
}

main().catch((e) => {
  console.error(`\nFailed: ${(e as Error).message}`);
  process.exit(1);
});
