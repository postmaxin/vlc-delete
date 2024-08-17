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

def find_target(target: str, start: Path) -> Path:
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
    return found.resolve()

def move_to_target(target: str, path: Path):
    if not path.exists():
        LOGGER.error("'%s' does not exist", path)
        raise KeyError(f"'{path}' does not exist")
    target_path = find_target(target, path.parent)
    destination: Path = target_path / path.parent.name / path.name
    if destination.exists():
        LOGGER.error("Can't move '%s': '%s' already exists", path, destination)
        raise KeyError(f"{destination} already exists")
    LOGGER.info("Moving '%s' to '%s'", path, destination)
    destination.parent.mkdir(exist_ok=True)
    path.rename(destination)

def remap_path(path: str) -> Path:
    path = path.replace('\\', '/')
    do = True
    while do:
        do = False
        for source, dest in mappings.items():
            if path.startswith(source):
                new_path = path.replace(source, dest, 1)
                LOGGER.debug("Mapping '%s' to '%s'", path, new_path)
                path = new_path
                do = True
                break
    return Path(path)

def main(argc=None, arg0=None):
    target = None
    if arg0:
        name = Path(arg0).name
        if name in targets:
            target = name
    parser = argparse.ArgumentParser()
    if not target:
        parser.add_argument("target", type=str, help="target foder")
    parser.add_argument("path", type=str, help="path to move")
    parser.add_argument(
        "--log-level", help="Logging level",
        default=os.environ.get("LOG_LEVEL", "info"))
    options = parser.parse_args(argc)
    if not target:
        target = options.target
    logging.basicConfig(
        level=options.log_level.upper(),
        format=LOG_FORMAT,
    )
    local_path = remap_path(options.path)
    file_log = logging.FileHandler(LOGFILE)
    file_formatter = logging.Formatter(LOG_FORMAT)
    file_log.setFormatter(file_formatter)
    LOGGER.addHandler(file_log)
    move_to_target(target, local_path.resolve())
    return(0)

if __name__ == "__main__":
   exit(main(sys.argv[1:], sys.argv[0]))