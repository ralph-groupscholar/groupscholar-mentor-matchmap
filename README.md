# Group Scholar Mentor Matchmap

Mentor Matchmap is a Dart CLI that helps Group Scholar staff match scholars with mentors using shared focus areas, region proximity, and available capacity. It persists mentor data, scholar data, and match decisions in PostgreSQL so the team can keep a living record of matching history.

## Features
- Seed mentors and scholars with realistic starter data
- Generate ranked match suggestions with clear reasoning and batch capacity checks
- Record match decisions into PostgreSQL for future review
- Report mentor capacity usage and recent match decisions
- Flag scholars with low-scoring or missing matches
- Surface tag gaps and regional capacity imbalances
- Uses per-project schema isolation to avoid conflicts

## Tech Stack
- Dart 3
- PostgreSQL (via the `postgres` package)

## Getting Started

Install dependencies:

```bash
dart pub get
```

Set the required environment variables:

```bash
export PGHOST=your-host
export PGPORT=23947
export PGDATABASE=postgres
export PGUSER=your-user
export PGPASSWORD=your-password
export PGSCHEMA=mentor_matchmap
export PGSSLMODE=disable
```

Seed the database:

```bash
dart run bin/groupscholar_mentor_matchmap.dart seed
```

Generate suggestions:

```bash
dart run bin/groupscholar_mentor_matchmap.dart suggest
```

Record the suggested matches:

```bash
dart run bin/groupscholar_mentor_matchmap.dart record
```

View a capacity report:

```bash
dart run bin/groupscholar_mentor_matchmap.dart report
```

Identify match gaps:

```bash
dart run bin/groupscholar_mentor_matchmap.dart gap --threshold 3
```

Review tag and region coverage:

```bash
dart run bin/groupscholar_mentor_matchmap.dart coverage
```

## Testing

```bash
dart test
```
