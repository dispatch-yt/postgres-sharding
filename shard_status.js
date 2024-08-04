const { execSync } = require('child_process');
const Table = require('cli-table3');

// Define variables
const MASTER = 'master';
const DB_USER = 'user';
const DB_NAME = 'citus';

// Function to run a command and get output
function runCommand(command) {
    const result = execSync(command, { encoding: 'utf8' }).trim();
    return result;
}

// Get shard information from the master node
const shardQuery = `
    SELECT pg_dist_shard.shardid AS shardid, relname AS table_name, nodename, nodeport
    FROM pg_dist_shard
    JOIN pg_dist_placement ON pg_dist_shard.shardid = pg_dist_placement.shardid
    JOIN pg_dist_node ON pg_dist_placement.groupid = pg_dist_node.groupid
    JOIN pg_class ON pg_class.oid = pg_dist_shard.logicalrelid
    WHERE pg_class.relname = 'vehicle_tracking';
`;

const shardsCommand = `docker-compose exec -T ${MASTER} psql -U ${DB_USER} -d ${DB_NAME} -c "${shardQuery}"`;
const shards = runCommand(shardsCommand);

const results = [];

if (shards) {
    // Split the output into lines and process each line
    const lines = shards.split('\n');

    // Skip the first line if it contains column headers
    lines.forEach(line => {
        // Skip lines that are headers, separators, or empty
        if (line.startsWith(' shardid') || line.startsWith('-') || line.trim() === '') {
            return;
        }

        // Split the line by '|' and strip whitespace from each element
        const columns = line.split('|').map(col => col.trim());

        if (columns.length >= 4) {
            const shardid = columns[0];
            const table = columns[1];
            const node = columns[2];
            const port = columns[3];

            // Check if shardid is a number
            if (/^[0-9]+$/.test(shardid)) {
                const shard = `${table}_${shardid}`;
                const dataQuery = `docker-compose exec -T ${node} psql -U ${DB_USER} -d ${DB_NAME} -c "SELECT * FROM ${shard};"`;
                const data = runCommand(dataQuery);
                
                if (data) {
                    results.push({ shard, node, data });
                }
            }
        }
    });
}

// Create a table
const table = new Table({
    head: ['Shard', 'Node', 'Data'],
    colWidths: [30, 20, 60]
});

// Add results to the table
results.forEach(result => {
    table.push([result.shard, result.node, result.data]);
});

// Print the table
console.log(table.toString());
