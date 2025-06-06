# 🧠 OWASP Juice Shop Penetration Test

This README documents the penetration testing workflow, findings, and context for a local test performed on **OWASP Juice Shop** deployed via Docker at `http://localhost:3000`. All supporting files and artifacts from this engagement are included in this repository.

---

## 🔍 Recon & Discovery

### Tools Used:

* `whatweb`, `ffuf`, `curl`, `nmap`, `strings`, `john`, `uncompyle6`, `keepass2john`, `binwalk`, `exiftool`

### Key Findings:

| Discovery     | Details                                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `/ftp`        | Directory listing exposed multiple sensitive files. Refer to files in [`ftp_loot/`](ftp_loot/).                              |
| `/robots.txt` | Disallowed `/ftp`, indicating it's intentionally hidden. See [`robots.txt`](ftp_loot/robots.txt) if downloaded.              |
| `/promotion`  | Accepts input in `?code=` parameter. See `ffuf` results in [`promotion_fuzz.txt`](ftp_loot/promotion_fuzz.txt) if generated. |
| `/snippets`   | Parameter fuzzed via wordlists. See `ffuf` results in [`snippets_fuzz.txt`](ftp_loot/snippets_fuzz.txt).                     |
| `/video`      | 10MB MP4 hosted. Analyzed for hidden content. See [`lol.mp4`](ftp_loot/lol.mp4).                                             |

---

## 📁 FTP Directory Looted

The `/ftp` directory was browsed and the following files were downloaded into [`ftp_loot/`](ftp_loot/):

| File                        | Description                                                                             |
| --------------------------- | --------------------------------------------------------------------------------------- |
| `acquisitions.md`           | May contain leaked internal business context.                                           |
| `announcement_encrypted.md` | Possibly obfuscated or encoded file.                                                    |
| `coupons_2013.md.bak`       | Backup containing sensitive coupon data.                                                |
| `encrypt.pyc`               | Compiled Python encryption logic (download attempt blocked).                            |
| `incident-support.kdbx`     | KeePass password vault file. See hash in [`output_john.txt`](ftp_loot/output_john.txt). |
| `package.json.bak`          | JS project structure possibly with dev secrets.                                         |
| `suspicious_errors.yml`     | Error log, may leak internals.                                                          |
| `eastere.gg`                | Likely a challenge-related or easter egg file.                                          |

---

## 🔓 Password Cracking

* Used `keepass2john` to extract hash from `incident-support.kdbx` → [`output_john.txt`](ftp_loot/output_john.txt)
* Cracking attempt:

  ```bash
  john output_john.txt --wordlist=rockyou.txt --format=KeePass
  ```
* Result: ❌ No password found (0g)
* Recommendation: Try with CrackStation or `hashcat`

---

## 🎥 MP4 File Analysis (`lol.mp4`)

* Extracted strings showed suspicious values like `*KEY`, `MKEY`
* Full string dump inspected via `strings`, `grep`, and optionally `binwalk`
* File located at: [`lol.mp4`](ftp_loot/lol.mp4)
* Suggested follow-up:

  * Use `binwalk -e lol.mp4` to extract hidden payloads
  * Play the video and look for visual easter eggs or QR codes

---

## 🧪 Other Notes

* `encrypt.pyc` download was blocked (403), as Juice Shop only serves `.md` or `.pdf`. Suggest renaming attempt like `encrypt.pyc.md`.
* Parameter discovery on `/snippets` was inconclusive but can be revisited with more aggressive wordlists.
* Promo fuzzing via `rockyou.txt` did not yield valid codes.

---

## 📦 File Reference(Sensitive) 
Extracted files from the victim as  follows:
| Path                                          | Purpose                                                           |
| --------------------------------------------- | ----------------------------------------------------------------- |
| [`ftp_loot/`](ftp_loot/)                      | All downloaded sensitive files from `/ftp`                        |
| [`lol.mp4`](ftp_loot/lol.mp4)                 | Large file analyzed for steganography/hidden content              |
| [`output_john.txt`](ftp_loot/output_john.txt) | Cracking hash extracted from `.kdbx`                              |
| `rockyou.txt`                                 | Used as wordlist in `john` and `ffuf` (not committed due to size) |

---

## ✅ Next Steps

* [ ] Retry cracking with stronger or extended wordlists
* [ ] Analyze `lol.mp4` with `binwalk`, `exiftool`, and visually
* [ ] Explore bypass techniques for `.pyc` download filters
* [ ] Continue fuzzing `/promotion` and `/snippets` with logic-based inputs

---

**Author**: Micheal
**Test Type**: Local PenTest
**Target App**: [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/)
