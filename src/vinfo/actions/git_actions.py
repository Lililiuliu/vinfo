import asyncio
import os
from vinfo.actions.base import ActionResult, BaseAction
from vinfo.core.models import GitInfo
from vinfo.providers.git_provider import GH_AUTH_LOGGED_IN


class EditGitConfigAction(BaseAction):
    name = "edit_config"
    description = "Open git global config in $EDITOR"

    async def execute(self, runner, info: GitInfo) -> ActionResult:
        editor = os.environ.get("EDITOR", "vi")
        try:
            result = await runner.run(f"git config --global --edit", timeout=5)
            if result.success:
                return ActionResult(success=True, message=f"Config opened in {editor}", output="")
            return ActionResult(success=False, message=f"Failed to open config: {result.stderr}", output="")
        except Exception as e:
            return ActionResult(success=False, message=str(e), output="")


class GhAuthLoginAction(BaseAction):
    name = "gh_auth"
    description = "Run GitHub CLI authentication flow"

    async def execute(self, runner, info: GitInfo) -> ActionResult:
        result = await runner.run("gh auth login", timeout=60)
        if result.success:
            return ActionResult(success=True, message="GitHub authentication complete", output=result.stdout)
        return ActionResult(success=False, message=f"GitHub auth failed: {result.stderr}", output=result.stdout)


class GhAuthStatusAction(BaseAction):
    name = "gh_status"
    description = "Show GitHub CLI authentication status"

    async def execute(self, runner, info: GitInfo) -> ActionResult:
        result = await runner.run("gh auth status", timeout=10)
        if result.success:
            return ActionResult(success=True, message="", output=result.stdout)
        return ActionResult(success=False, message="Not authenticated with GitHub", output=result.stdout)


class ShowRemotesAction(BaseAction):
    name = "show_remotes"
    description = "List git remote repositories"

    async def execute(self, runner, info: GitInfo) -> ActionResult:
        result = await runner.run("git remote -v", timeout=5)
        if not result.success:
            return ActionResult(success=False, message="Not in a git repository", output="")
        if not result.stdout:
            return ActionResult(success=True, message="No remotes configured", output="")
        return ActionResult(success=True, message="", output=result.stdout)


class ShowCurrentBranchAction(BaseAction):
    name = "current_branch"
    description = "Show current git branch"

    async def execute(self, runner, info: GitInfo) -> ActionResult:
        result = await runner.run("git branch --show-current", timeout=5)
        if result.success:
            branch = result.stdout.strip()
            return ActionResult(success=True, message=f"Current branch: {branch}", output=branch)
        return ActionResult(success=False, message="Not in a git repository", output="")


class GitUserIdentityAction(BaseAction):
    name = "show_identity"
    description = "Show configured git user identity"

    async def execute(self, runner, info: GitInfo) -> ActionResult:
        name_res, email_res = await asyncio.gather(
            runner.run("git config --global user.name", timeout=5),
            runner.run("git config --global user.email", timeout=5),
        )
        name = name_res.stdout.strip() if name_res.success else "NOT SET"
        email = email_res.stdout.strip() if email_res.success else "NOT SET"
        output = f"Name:  {name}\nEmail: {email}"
        status = "OK" if name != "NOT SET" and email != "NOT SET" else "INCOMPLETE"
        return ActionResult(success=status == "OK", message=f"Identity: {status}", output=output)


def get_git_actions(info: GitInfo) -> list[BaseAction]:
    actions = [
        GitUserIdentityAction(),
        EditGitConfigAction(),
        ShowCurrentBranchAction(),
        ShowRemotesAction(),
    ]
    if info.gh_installed:
        actions.insert(2, GhAuthStatusAction())
        if info.gh_auth_status != GH_AUTH_LOGGED_IN:
            actions.insert(3, GhAuthLoginAction())
    return actions
