# BDr Translate TV — Samsung Tizen experimental app

**Arabic:** نسخة اختبارية فقط. تعرض نصوصًا عربية ثابتة، وتحاول إظهار صورة HDMI من خلال واجهة TVWindow على بعض تلفزيونات Samsung. لا تترجم قراند تلقائيًا، ولا يوجد تطبيق آيفون في هذه النسخة.

## Publish on GitHub

1. Create a new public GitHub repository, e.g. `BDr-Translate-TV`.
2. Upload all files **including** `.github/workflows/build.yml` (do not upload the outer ZIP as a single file).
3. Open the GitHub **Actions** tab and run **Build test WGT** using `Run workflow`, or push a change to `main`.
4. Download the `BDr-Translate-TV-unsigned-WGT` artifact from the successful workflow run and extract the `.wgt` file.
5. In Apps2Samsung, select **Custom WGT** and select the file, allowing Apps2Samsung to sign it if supported.
6. For adding GitHub as `Your sources`, create a GitHub Release and attach the `.wgt` file. The repository alone is not an installable package.

## Test

- Keep PS5 on, and leave HDMI connected to the Samsung TV.
- Open the BDr Translate test app and pick the HDMI source.
- If video plus Arabic demo text shows up, we've validated the approach on this TV. If not, note the error.
- Some models reject HDMI capture in TVWindow. A traditional application overlay does not stay over the TV's normal HDMI UI.

## Packaging notes

GitHub Actions makes an **unsigned** ZIP-format WGT for an *installation feasibility test*. Apps2Samsung must re-sign it, and it is not guaranteed to be accepted without full Tizen build/signing. Never store signing passwords or private certificate keys in a public repository.

Source context: Samsung Tizen TVWindow API: https://developer.samsung.com/smarttv/develop/api-references/tizen-web-device-api-references/tvwindow-api.html
