import { Hono } from 'hono';
import crypto from 'crypto';

const slack = new Hono();

function verifySlackRequest(signingSecret: string, timestamp: string, body: string, signature: string): boolean {
  const baseString = `v0:${timestamp}:${body}`;
  const hash = 'v0=' + crypto.createHmac('sha256', signingSecret).update(baseString).digest('hex');

  return crypto.timingSafeEqual(Buffer.from(hash, 'utf8'), Buffer.from(signature, 'utf8'));
}

slack.post('/', async (c) => {
  const signingSecret = process.env.SLACK_SIGNING_SECRET;

  // Validate Slack Signature
  const timestamp = c.req.header('X-Slack-Request-Timestamp');
  const slackSignature = c.req.header('X-Slack-Signature');
  const body = await c.req.text(); // Extract raw body for verification

  if (!signingSecret || !timestamp || !slackSignature || !verifySlackRequest(signingSecret, timestamp, body, slackSignature)) {
    return c.text('Invalid Slack request', 403); // Reject if verification fails
  }

  const parsedBody = JSON.parse(body);
  const { type, challenge, event } = parsedBody;


  // Handle Slack's URL verification request
  if (type === 'url_verification') {
    return c.json({ challenge }); // Respond with the challenge value
  }

  // Handle Slack events (like user messages, etc.)
  if (type === 'event_callback' && event) {
    console.log('Slack Event Received:', event);

    // Add your Slack event handling logic here (e.g., replying to a message)
  }

  return c.text('OK'); // Respond with 200 OK for acknowledgment
});

export default slack;