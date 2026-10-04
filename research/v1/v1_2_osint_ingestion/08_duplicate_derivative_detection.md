# V1.2 DUPLICATE AND DERIVATIVE DETECTION

`OsintIngestionService.ingestRawObservation()` checks SHA-256 `contentHash` in repository storage. Duplicate content sets `isDuplicate = true`.
