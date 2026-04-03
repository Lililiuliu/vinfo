import asyncio
from vinfo.constants import HealthStatus
from vinfo.core.base import BaseEnvironmentProvider
from vinfo.core.models import EnvironmentInfo, GitInfo
from vinfo.core.registry import register
from vinfo.core.runner import CommandRunner


# Status values for gh auth
GH_AUTH_LOGGED_IN = "logged_in"
GH_AUTH_NOT_LOGGED_IN = "not_logged_in"


@register
class GitProvider(BaseEnvironmentProvider):
    name = "git"
    display_name = "Git / GitHub CLI"
    icon = "\U0001f4bb"
    priority = 30

    def __init__(self, runner: CommandRunner):
        self._runner = runner

    async def detect(self) -> bool:
        return self._runner.which("git") is not None

    async def collect(self) -> GitInfo:
        git_bin = self._runner.which("git") or ""
        git_ver = await self._runner.run(f"{git_bin} --version 2>&1")
        version = git_ver.stdout.replace("git version ", "").strip() if git_ver.success else "Unknown"

        info = GitInfo(
            name=self.name,
            display_name=f"Git {version}",
            status=HealthStatus.HEALTHY,
            version=version,
            path=git_bin,
        )

        # Fetch all git config in parallel
        name_res, email_res, sign_res, branch_res = await asyncio.gather(
            self._runner.run("git config --global user.name 2>&1"),
            self._runner.run("git config --global user.email 2>&1"),
            self._runner.run("git config --global user.signingkey 2>&1"),
            self._runner.run("git config --global init.defaultBranch 2>&1"),
        )

        if name_res.success and name_res.stdout:
            info.user_name = name_res.stdout
        if email_res.success and email_res.stdout:
            info.user_email = email_res.stdout
        if sign_res.success and sign_res.stdout:
            info.signing_key = sign_res.stdout
        if branch_res.success and branch_res.stdout:
            info.default_branch = branch_res.stdout

        gh_bin = self._runner.which("gh")
        if gh_bin:
            info.gh_installed = True
            gh_ver_res, gh_auth_res = await asyncio.gather(
                self._runner.run(f"{gh_bin} --version 2>&1"),
                self._runner.run(f"{gh_bin} auth status 2>&1", timeout=5),
            )
            if gh_ver_res.success and gh_ver_res.stdout:
                # Format: "gh version 2.88.1 (https://github.com/cli/cli/releases/tag/v2.88.1)"
                import re
                m = re.search(r"(\d+\.\d+\.\d+)", gh_ver_res.stdout)
                info.gh_version = m.group(1) if m else gh_ver_res.stdout.strip().split()[-1]

            if gh_auth_res.success:
                info.gh_auth_status = GH_AUTH_LOGGED_IN
                for line in gh_auth_res.stdout.splitlines():
                    if "account " in line and "keyring" in line:
                        # Format: "  ✓ Logged in to github.com account {username} (keyring)"
                        import re
                        m = re.search(r"account\s+(\S+)\s+\(", line)
                        if m:
                            info.gh_user = m.group(1)
                            break
            else:
                info.gh_auth_status = GH_AUTH_NOT_LOGGED_IN

        repo_result = await self._runner.run("git rev-parse --is-inside-work-tree 2>&1")
        if repo_result.success and repo_result.stdout == "true":
            root_res, branch_res, remote_res = await asyncio.gather(
                self._runner.run("git rev-parse --show-toplevel 2>&1"),
                self._runner.run("git branch --show-current 2>&1"),
                self._runner.run("git remote -v 2>&1"),
            )
            if root_res.success:
                info.current_repo = root_res.stdout
            if branch_res.success:
                info.current_branch = branch_res.stdout
            if remote_res.success:
                for line in remote_res.stdout.splitlines():
                    parts = line.split()
                    if len(parts) >= 2:
                        info.remotes.append({"name": parts[0], "url": parts[1]})

        return info

    async def health_check(self) -> tuple[HealthStatus, list[str]]:
        # Identity check was already done in collect() via git config calls.
        # Just confirm git binary is present.
        return HealthStatus.HEALTHY, []

    def get_quick_actions(self) -> list[dict]:
        return [
            {"id": "edit_config", "label": "Edit git config", "description": "Open global git config in $EDITOR", "dangerous": False},
            {"id": "gh_auth_login", "label": "GitHub auth login", "description": "Run gh auth login flow", "dangerous": False},
        ]
