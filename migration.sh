#!/bin/bash

# Variables
MASTER="master"
WORKER1="worker1"
WORKER2="worker2"
DB_USER="user"
DB_NAME="citus"

# Add worker nodes
docker-compose exec $MASTER psql -U $DB_USER -d $DB_NAME -c "SELECT master_add_node('$WORKER1', 5432);"
docker-compose exec $MASTER psql -U $DB_USER -d $DB_NAME -c "SELECT master_add_node('$WORKER2', 5432);"

# Vehicle tracking table
docker-compose exec $MASTER psql -U $DB_USER -d $DB_NAME -c "CREATE TABLE IF NOT EXISTS vehicle_tracking(id serial, vin VARCHAR(17), latitude decimal, longitude decimal, speed decimal, PRIMARY KEY (id, vin));"

# Distributed table
docker-compose exec $MASTER psql -U $DB_USER -d $DB_NAME -c "SELECT create_distributed_table('vehicle_tracking', 'vin');"

echo "Migration completed."
