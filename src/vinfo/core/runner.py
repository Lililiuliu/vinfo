import asyncio
import shutil
from dataclasses import dataclass


@dataclass
class CommandResult:
    success: bool
    stdout: str
    stderr: str
    return_code: int
    command: str


class CommandRunner:
    DEFAULT_TIMEOUT = 15

    def __init__(self, timeout: int = DEFAULT_TIMEOUT):
        self.timeout = timeout

    async def run(
        self,
        cmd: str,
        *,
        check: bool = False,
        timeout: int | None = None,
        env: dict | None = None,
    ) -> CommandResult:
        proc = await asyncio.create_subprocess_shell(
            cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        try:
            stdout, stderr = await asyncio.wait_for(
                proc.communicate(), timeout=timeout or self.timeout
            )
        except asyncio.TimeoutError:
            proc.kill()
            await proc.wait()
            return CommandResult(
                success=False,
                stdout="",
                stderr="Command timed out",
                return_code=-1,
                command=cmd,
            )

        result = CommandResult(
            success=(proc.returncode == 0),
            stdout=stdout.decode("utf-8", errors="replace").strip(),
            stderr=stderr.decode("utf-8", errors="replace").strip(),
            return_code=proc.returncode,
            command=cmd,
        )
        if check and not result.success:
            raise RuntimeError(f"Command failed: {cmd}\n{result.stderr}")
        return result

    def which(self, name: str) -> str | None:
        return shutil.which(name)

    async def run_many(self, cmds: list[str]) -> list[CommandResult]:
        tasks = [self.run(cmd) for cmd in cmds]
        return await asyncio.gather(*tasks)
