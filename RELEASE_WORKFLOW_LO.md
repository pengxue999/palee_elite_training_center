# ຄູ່ມືອອກເວີຊັນ ແລະ ອັບເດດລູກຄ້າ (Windows)

ເອກະສານນີ້ແມ່ນຂັ້ນຕອນທີ່ຕ້ອງເຮັດທຸກຄັ້ງ ເມື່ອຈະອອກເວີຊັນໃໝ່ ເພື່ອໃຫ້ລູກຄ້າກົດອັບເດດແລ້ວໄດ້ເວີຊັນລ່າສຸດ.

## 1. ລະບົບອັບເດດນີ້ເຮັດວຽກແນວໃດ

ໂປຣແກຣມຈະກວດເບິ່ງໄຟລ໌ `version.json` ຈາກ GitHub:

- `version.json` ບອກເວີຊັນລ່າສຸດ
- `url` ຄືລິ້ງ installer ທີ່ລູກຄ້າຈະດາວໂຫຼດ
- `notes` ຄືຂໍ້ຄວາມ release notes

ໂປຣແກຣມຈະປຽບທຽບ:

- ເວີຊັນທີ່ຕິດຕັ້ງຢູ່ໃນເຄື່ອງລູກຄ້າ
- ເວີຊັນໃນ `version.json`

ຖ້າ `version.json` ໃໝ່ກວ່າ ຈະຂຶ້ນປຸ່ມໃຫ້ອັບເດດ.

## 2. ກົດສຳຄັນຫຼາຍ

ຫ້າມໃຊ້ເວີຊັນເກົ່າຊ້ຳ. ຕ້ອງເພີ່ມເລກເວີຊັນຂຶ້ນທຸກຄັ້ງ.

ຕົວຢ່າງ:

- `1.0.0`
- `1.0.1`
- `1.0.2`
- `1.1.0`

ຖ້າລູກຄ້າມີ `1.0.5` ຢູ່ແລ້ວ ແຕ່ເຈົ້າເຮັດ `1.0.0` ອີກ, ລະບົບຈະບໍ່ອັບເດດ ເພາະ `1.0.0` ບໍ່ໃໝ່ກວ່າ `1.0.5`.

## 3. ໄຟລ໌ທີ່ຕ້ອງຮູ້

- `pubspec.yaml` ເກັບເວີຊັນແອັບ
- `version.json` ເກັບ metadata ສຳລັບອັບເດດ
- `installer.iss` ໃຊ້ສ້າງ installer ດ້ວຍ Inno Setup
- `.github/workflows/build-windows.yml` ໃຊ້ build release ອັດຕະໂນມັດເມື່ອ push tag `v*`

## 4. ຂັ້ນຕອນທີ່ຖືກຕ້ອງໃນທຸກຄັ້ງທີ່ຈະອອກເວີຊັນໃໝ່

### ຂັ້ນ 1: ແກ້ໂຄດໃຫ້ສຳເລັດ

ແກ້ໄຂ feature, bug, UI ຫຼື logic ໃຫ້ຮຽບຮ້ອຍກ່ອນ.

### ຂັ້ນ 2: ປ່ຽນເວີຊັນໃນ `pubspec.yaml`

ຕົວຢ່າງ:

```yaml
version: 1.0.6
```

ໝາຍເຫດ:

- ເວີຊັນນີ້ຄືເວີຊັນທີ່ລູກຄ້າຈະເຫັນໃນແອັບຫຼັງອັບເດດ
- ລະບົບຂອງເຈົ້າອ່ານເວີຊັນຈາກ package info ຂອງ build ນັ້ນ

### ຂັ້ນ 3: commit ໂຄດລົງ `main`

```powershell
git add .
git commit -m "Release 1.0.6"
git push origin main
```

### ຂັ້ນ 4: ສ້າງ tag ຕາມເວີຊັນ

```powershell
git tag v1.0.6
git push origin v1.0.6
```

ຕ້ອງໃຫ້ tag ເປັນຮູບແບບ `v1.0.6` ເທົ່ານັ້ນ.

### ຂັ້ນ 5: ໃຫ້ GitHub Actions ເຮັດວຽກ

workflow ຈະເຮັດສິ່ງຕໍ່ໄປນີ້ອັດຕະໂນມັດ:

1. build Windows app
2. ສ້າງ installer ດ້ວຍ Inno Setup
3. ສ້າງ GitHub Release
4. upload ໄຟລ໌ `PaleeEliteTrainingCenter-Setup.exe`
5. ອັບເດດ `version.json` ໃນ branch `main`

### ຂັ້ນ 6: ກວດສອບ GitHub Release

ຫຼັງຈາກ workflow ຈົບ ໃຫ້ກວດ 3 ຢ່າງ:

1. ມີ release `v1.0.6`
2. ມີ asset `PaleeEliteTrainingCenter-Setup.exe`
3. `version.json` ຖືກອັບເດດເປັນ `1.0.6`

### ຂັ້ນ 7: ທົດສອບໃນແອັບຈິງ

ໃນເຄື່ອງທົດສອບທີ່ຍັງເປັນເວີຊັນເກົ່າ:

1. ເປີດແອັບ
2. ກົດປຸ່ມກວດສອບອັບເດດ
3. ຕ້ອງຂຶ້ນວ່າພົບເວີຊັນໃໝ່ `1.0.6`
4. ກົດອັບເດດດຽວນີ້
5. ໃຫ້ installer ເຮັດວຽກຈົນສຳເລັດ
6. ເປີດແອັບຄືນ
7. ກວດເບິ່ງວ່າເວີຊັນປັດຈຸບັນຂຶ້ນເປັນ `1.0.6`

## 5. ຖ້າຈະ build installer ເອງໃນເຄື່ອງ

ຖ້າຈະ build ເອງໂດຍບໍ່ລໍຖ້າ GitHub Actions ໃຫ້ເຮັດຕາມນີ້:

### 5.1 build Windows release

```powershell
flutter pub get
flutter build windows --release --build-name 1.0.6 --build-number 1
```

### 5.2 ສ້າງ installer ດ້ວຍ Inno Setup

ເຄື່ອງຂອງເຈົ້າມີ Inno Setup ຢູ່:

```text
D:\Inno Setup 6
```

ໃຫ້ໃຊ້ຄຳສັ່ງນີ້:

```powershell
& "D:\Inno Setup 6\ISCC.exe" "/DMyAppVersion=1.0.6" "installer.iss"
```

ຫຼັງຈາກນັ້ນ ໄຟລ໌ installer ຈະອອກຢູ່ໂຟນເດີ `Output`.

## 6. ຖ້າຈະອັບເດດແບບ manual ດ້ວຍຕົນເອງ

ຖ້າ GitHub Actions ບໍ່ໄດ້ໃຊ້ ຫຼື ເຈົ້າຢາກເຮັດເອງ ຕ້ອງເຮັດ 4 ຢ່າງນີ້ໃຫ້ຄົບ:

1. build app ເປັນເວີຊັນໃໝ່
2. ສ້າງ installer ໃໝ່
3. upload installer ໄປທີ່ GitHub Release ຂອງ tag ນັ້ນ
4. ແກ້ `version.json` ໃຫ້ຊີ້ໄປຫາ installer ໃໝ່

ຕົວຢ່າງ `version.json`:

```json
{
  "version": "1.0.6",
  "url": "https://github.com/pengxue999/palee_elite_training_center/releases/download/v1.0.6/PaleeEliteTrainingCenter-Setup.exe",
  "notes": "Windows release 1.0.6"
}
```

ຫຼັງຈາກນັ້ນໃຫ້ commit ແລະ push `version.json` ຂຶ້ນ `main`.

## 7. ສິ່ງທີ່ຕ້ອງກົງກັນທຸກຄັ້ງ

ມີ 4 ບ່ອນທີ່ຕ້ອງສຳພັນກັນ:

1. `pubspec.yaml` ຕ້ອງເປັນ `1.0.6`
2. Git tag ຕ້ອງເປັນ `v1.0.6`
3. `version.json` ຕ້ອງເປັນ `1.0.6`
4. release URL ຕ້ອງເປັນ `.../download/v1.0.6/PaleeEliteTrainingCenter-Setup.exe`

ຖ້າບໍ່ກົງກັນ ອາດຈະເກີດອາການ:

- ແອັບບໍ່ເຫັນວ່າມີ update
- ກົດອັບເດດແລ້ວ download ບໍ່ໄດ້
- ຕິດຕັ້ງແລ້ວ ແຕ່ເວີຊັນບໍ່ຂຶ້ນຕາມທີ່ຕ້ອງການ

## 8. ເປັນຫຍັງຫຼັງອັບເດດແລ້ວ ແອັບຈຶ່ງຕ້ອງຂຶ້ນເວີຊັນໃໝ່

ເພາະລະບົບຂອງເຈົ້າອ່ານເວີຊັນຈາກ package info ຂອງ build ນັ້ນ. ດັ່ງນັ້ນຖ້າ build ດ້ວຍ:

```powershell
flutter build windows --release --build-name 1.0.6
```

ຫຼັງລູກຄ້າຕິດຕັ້ງສຳເລັດ ແອັບຈະອ່ານໄດ້ເປັນ `1.0.6`.

## 9. checklist ສັ້ນໆ ກ່ອນປ່ອຍເວີຊັນ

ກ່ອນປ່ອຍເວີຊັນໃໝ່ ໃຫ້ເຊັກອັນນີ້ທຸກຄັ້ງ:

1. ແກ້ໂຄດເສັດແລ້ວ
2. `pubspec.yaml` ປ່ຽນເປັນເວີຊັນໃໝ່ແລ້ວ
3. commit ແລ້ວ
4. push `main` ແລ້ວ
5. push tag `vX.Y.Z` ແລ້ວ
6. GitHub Release ສ້າງສຳເລັດແລ້ວ
7. `version.json` ຖືກອັບເດດແລ້ວ
8. ທົດສອບການອັບເດດໃນເຄື່ອງເກົ່າແລ້ວ
9. ຫຼັງອັບເດດ ແອັບຂຶ້ນເປັນເວີຊັນໃໝ່ແລ້ວ

## 10. ຖ້າຈະເລີ່ມໃໝ່ຈາກ `1.0.0`

ໃຫ້ເຮັດສະເພາະຕອນທີ່ຍັງບໍ່ມີລູກຄ້າໃຊ້ເວີຊັນສູງກວ່າ. ຖ້າມີລູກຄ້າໃຊ້ `1.0.5` ແລ້ວ ບໍ່ຄວນກັບໄປ `1.0.0`.

ຖ້າຈະ reset ຈິງໆ:

1. ລົບ release ເກົ່າໃນ GitHub
2. ລົບ tag ເກົ່າໃນ local ແລະ remote
3. ຕັ້ງ `pubspec.yaml` ແລະ `version.json` ເປັນ `1.0.0`
4. build ແລະສ້າງ installer ໃໝ່
5. ສ້າງ tag `v1.0.0` ໃໝ່
6. ປ່ອຍ release ໃໝ່

ແຕ່ຖ້າມີລູກຄ້າໃຊ້ເວີຊັນສູງກວ່າຢູ່ແລ້ວ ແນະນຳໃຫ້ໄປຕໍ່ `1.0.6` ຫຼື `1.1.0` ເລີຍ.