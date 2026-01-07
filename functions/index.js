const functions = require('firebase-functions');
const twilio = require('twilio');

// Twilio credentials (DO NOT PUSH TO GITHUB)
const TWILIO_ACCOUNT_SID = 'YOUR_TWILIO_SID_HERE';
const TWILIO_API_SECRET = 'YOUR_TWILIO_SECRET_HERE';

// Generate Twilio Access Token
exports.getTwilioToken = functions.https.onRequest(async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');

    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'GET, POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.status(204).send('');
        return;
    }

    try {
        const { identity, roomName } = req.query;

        if (!identity || !roomName) {
            res.status(400).json({ error: 'Missing identity or roomName' });
            return;
        }

        const AccessToken = twilio.jwt.AccessToken;
        const VideoGrant = AccessToken.VideoGrant;

        // Create access token
        const token = new AccessToken(
            TWILIO_ACCOUNT_SID,
            TWILIO_ACCOUNT_SID, // Using API Key SID as Account SID
            TWILIO_API_SECRET,
            { identity: identity }
        );

        // Create video grant
        const videoGrant = new VideoGrant({
            room: roomName,
        });

        token.addGrant(videoGrant);

        res.json({
            token: token.toJwt(),
            identity: identity,
            roomName: roomName,
        });
    } catch (error) {
        console.error('Error generating token:', error);
        res.status(500).json({ error: error.message });
    }
});
