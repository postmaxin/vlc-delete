#!/usr/bin/env python3

from pathlib import Path
import argparse
import logging
import sys
import os

LOGFILE = Path(os.environ["HOME"]) / "remote-action.log"
LOGGER = logging.getLogger(__name__)
LOG_FORMAT = "%(asctime)s [%(process)d] [%(levelname)s] [%(name)s] %(message)s"

mappings = {
    'S:/': '/sanity/',
    '//192.168.2.68/': '/sanity/',
}

prefixes = {
    '/sanity/archive',
    '/sanity/video/new'
}

targets = {'remove', 'keep'}

def find_target(target: str, start: Path) -> str:
    found = None
    path = start
    while path.parent != path:
        path = path.parent
        target_path = path / target
        if target_path.exists():
            found = target_path
            break
    if not found:
        raise KeyError(f"Could not find '{target}' above '{start}")

def move_to_target(target: str, path: Path):
    if not path.exists():
        LOGGER.error("'%s' does not exist", path)
        raise KeyError(f"'{path}' does not exist")
    target_path = find_target(target, path.parent)


def remap_path(path: str):
    path = path.replace('\\', '/') 

def main(argc=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("target", type=str, help="target foder")
    parser.add_argument("path", type=str, help="path to move")
    parser.add_argument(
        "--log-level", help="Logging level",
        default=os.environ.get("LOG_LEVEL", "info"))
    options = parser.parse_args(argc)
    logging.basicConfig(
        level=options.log_level.upper(),
        format=LOG_FORMAT,
    )
    local_path = remap_path(options.path)
    file_log = logging.FileHandler(LOGFILE)
    file_formatter = logging.Formatter(LOG_FORMAT)
    file_log.setFormatter(file_formatter)
    LOGGER.addHandler(file_log)
    move_to_target(options.target, local_path)
    return(0)

if __name__ == "__main__":
   exit(main(sys.argv[1:]))