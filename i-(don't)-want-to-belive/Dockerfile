FROM heroiclabs/nakama:3.25.0

RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo '/nakama/nakama migrate up --database.address "$DATABASE_URL"' >> /entrypoint.sh && \
    echo 'exec /nakama/nakama --config /nakama/data/local.yaml --database.address "$DATABASE_URL"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
