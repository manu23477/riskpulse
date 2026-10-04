# V1.1 SOURCE INDEPENDENCE MODEL

`EvidenceFusionService.assessSourceIndependence()` groups evidence items by `sourcePublisher` / `sourceSystem` / `contentHash`. Derivative postings or copied news articles from the same publisher do NOT increment `independentSourceCount`.
