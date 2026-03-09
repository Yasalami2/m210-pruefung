exports.handler = async () => {
    return {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
        },
        body: JSON.stringify({ 
            auto: "Tesla Model 3", 
            besitzer: "Prüfling Yasalami",
            status: "Backend erfolgreich verbunden!" 
        })
    };
};
