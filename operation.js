const { Client } = require('pg');

// Database connection details
const dbConfig = {
    user: 'user',
    host: '127.0.0.1',
    database: 'citus',
    password: 'password',
    port: 5432,
};

async function connectToDb() {
    const client = new Client(dbConfig);
    await client.connect();
    return client;
}

async function insertData(vin, lat, long, speed) {
    const client = await connectToDb();
    await client.query('INSERT INTO vehicle_tracking (vin, latitude, longitude, speed) VALUES ($1, $2, $3, $4)', 
        [vin, lat, long, speed]);
    await client.end();
}

async function retriveTrackingDetails() {
    const client = await connectToDb();
    const res = await client.query('SELECT * FROM vehicle_tracking');
    await client.end();
    return res.rows;
}

(async () => {
    const args = process.argv.slice(2);
    const operation = args[0];
    console.log('operation', operation);

    if (operation === 'insert') {
        const vin = args[1];
        await insertData(vin, args[2], args[3], args[4]);
        console.log(`Inserted location for vin: ${vin}`);
    } else if (operation === 'view') {
        const allUsers = await retriveTrackingDetails();
        allUsers.forEach(user => {
            console.log(user);
        });
    }
})();
