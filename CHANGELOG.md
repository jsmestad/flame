# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Change API to return `{:ok, Flame.IdToken.t() | Flame.SessionCookie.t()}` instead of `{:ok, String.t(), String.t()}`
- Remove Flame.Finch from supervisor, use built-in Finch from Goth for requests.

## [0.1.0] - 2022-04-28

- Initial Release
