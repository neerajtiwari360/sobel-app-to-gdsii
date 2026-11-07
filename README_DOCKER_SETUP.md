# Sobel Docker ASIC flow overlay

Unzip/merge these files into `D:\Github\sobel-app-to-gdsii`.

Do not delete the existing `python/`, `rtl/` or `tb/` directories.

Run from PowerShell:

```powershell
docker compose build
docker compose run --rm sobel-asic
```

Details: `docs/DOCKER_FLOW.md`
