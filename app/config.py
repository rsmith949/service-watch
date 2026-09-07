"""Runtime configuration, read from environment variables."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Settings loaded from WATCH_* environment variables."""

    model_config = SettingsConfigDict(env_prefix="WATCH_", env_file=".env")

    targets: str = ""
    warn_days: int = 14

    def target_list(self) -> list[str]:
        """Split the comma-separated targets into a clean list."""
        return [t.strip() for t in self.targets.split(",") if t.strip()]
