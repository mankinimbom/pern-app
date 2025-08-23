# GitHub Container Registry Authentication Setup

## Issue
The GitHub Actions workflow failed with:
```
ERROR: failed to push ghcr.io/mankinimbom/pern-frontend:main: denied: installation not allowed to Write organization package
```

## Solution
You need to create a Personal Access Token (PAT) with package write permissions.

## Steps to Fix

### 1. Create Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Set expiration (recommended: 90 days or custom)
4. Select these scopes:
   - ✅ `write:packages` - Upload packages to GitHub Package Registry
   - ✅ `read:packages` - Download packages from GitHub Package Registry
   - ✅ `repo` - Full control of private repositories (if needed)

5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again)

### 2. Add Token to Repository Secrets

1. Go to your repository: https://github.com/mankinimbom/pern-app
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `CR_PAT`
5. Value: Paste your token
6. Click "Add secret"

### 3. Alternative: Use GITHUB_TOKEN (if preferred)

If you prefer to use GITHUB_TOKEN instead of PAT, update the workflow:

```yaml
- name: Log in to Container Registry
  uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

But you'll need to ensure your repository has package write permissions.

## Current Status

- ✅ Updated workflow created: `.github/workflows/build-push-standard.yml`
- ❌ Missing `CR_PAT` secret in repository
- ⏳ Waiting for PAT setup to retry workflow

## Test After Setup

Once you add the `CR_PAT` secret:

1. Push a small change to trigger the workflow:
   ```bash
   git commit --allow-empty -m "Test image build with PAT"
   git push origin main
   ```

2. Monitor the workflow in GitHub Actions tab

3. Verify images are pushed to GHCR:
   - https://github.com/mankinimbom/pern-backend/pkgs/container/pern-backend
   - https://github.com/mankinimbom/pern-frontend/pkgs/container/pern-frontend

## Package Visibility

After successful push, you may need to make packages public:

1. Go to package page on GitHub
2. Settings → Change visibility → Public
3. This allows Kubernetes to pull without authentication
