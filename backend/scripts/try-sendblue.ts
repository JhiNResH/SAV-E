// Standalone Sendblue-bot tester — exercises the bot logic WITHOUT booting the
// DB-coupled server (no DATABASE_URL needed). Only GEMINI_API_KEY is required for
// the venue extraction; add SENDBLUE_* + `--send <number>` to actually text it.
//
//   GEMINI_API_KEY=... npx tsx scripts/try-sendblue.ts "https://www.instagram.com/reel/DXzN9wsBFRw/"
//   GEMINI_API_KEY=... SENDBLUE_API_KEY_ID=... SENDBLUE_API_SECRET=... \
//     npx tsx scripts/try-sendblue.ts "<url>" --send +8869xxxxxxxx
import {
  fetchLinkCaption,
  extractVenueFromCaption,
  formatVenueReply,
  firstUrlInText,
  SendblueClient,
} from "../src/sendblueBot.js";

const input = process.argv[2];
const sendIdx = process.argv.indexOf("--send");
const sendTo = sendIdx > -1 ? process.argv[sendIdx + 1] : undefined;

if (!input) {
  console.error('usage: npx tsx scripts/try-sendblue.ts "<url-or-text>" [--send +number]');
  process.exit(1);
}

const url = firstUrlInText(input) ?? input;
console.log("→ URL:", url);

const { caption } = await fetchLinkCaption(url);
console.log("\n→ CAPTION (first 400):\n" + (caption ? caption.slice(0, 400) : "(empty — thin/age-restricted?)"));

if (!process.env.GEMINI_API_KEY && !process.env.GOOGLE_GEMINI_API_KEY) {
  console.log("\n⚠️  No GEMINI_API_KEY set — caption fetched but extraction skipped.");
  process.exit(0);
}

const venue = await extractVenueFromCaption(caption);
console.log("\n→ VENUE:", venue ?? "(none)");
const reply = venue ? formatVenueReply(venue) : "Couldn't find a clear place in that one.";
console.log("\n→ REPLY:\n" + reply);

if (sendTo) {
  if (!venue) {
    console.log("\n(no venue → not sending)");
  } else {
    await new SendblueClient().sendMessage(sendTo, reply);
    console.log("\n✅ sent to", sendTo);
  }
}
