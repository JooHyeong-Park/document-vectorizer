"""Dispatch application commands for local and deployment verification."""

import argparse

from adapters.commands.commands import documents_process
from vectorizer.contracts.constants import HttpApiPath

COMMAND_ARGUMENT = "command"
PAYLOAD_ARGUMENT = "payload"
PAYLOAD_OPTION = f"--{PAYLOAD_ARGUMENT}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(COMMAND_ARGUMENT)
    parser.add_argument(
        PAYLOAD_OPTION,
        required=True,
        help='JSON request payload, for example {"blob_path":"documents/file.txt"}',
    )
    args = parser.parse_args()

    command = getattr(args, COMMAND_ARGUMENT).lstrip("/")
    if command.startswith("api/"):
        command = command.removeprefix("api/")

    match command:
        case HttpApiPath.DOCUMENTS_PROCESS:
            return documents_process(getattr(args, PAYLOAD_ARGUMENT))
        case _:
            parser.error(f"unsupported command: {getattr(args, COMMAND_ARGUMENT)}")


if __name__ == "__main__":
    raise SystemExit(main())
