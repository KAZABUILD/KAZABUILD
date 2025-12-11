FROM python:3.11-slim-bullseye

# Install SQL Server drivers
RUN apt-get update && apt-get install -y unixodbc unixodbc-dev curl gnupg \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17

WORKDIR /app

# COPY EVERYTHING in the 'database' folder (includes scripts AND buildcores-open-db)
COPY . .

RUN pip install -r requirements.txt

# Run the script
# Notice the path is now 'scripts/import_buildcores.py'
# And input-dir is 'buildcores-open-db' (based on your tree output)
CMD python scripts/import_buildcores.py \
    --input-dir ./buildcores-open-db \
    --connection-string "Server=mssql.railway.internal,1433;Database=kazabuild_db;UID=sa;PWD=${DB_PASSWORD};TrustServerCertificate=yes;" \
    --component-types CPU GPU MOTHERBOARD MEMORY STORAGE POWER_SUPPLY CASE CASE_FAN COOLER MONITOR \
    --truncate \
    --dedupe \
    --batch-size 2000 \
    && \
    python scripts/check_compatibilities.py \
    --connection-string "Server=mssql.railway.internal,1433;Database=kazabuild_db;UID=sa;PWD=${DB_PASSWORD};TrustServerCertificate=yes;" \
    --batch-size 2000