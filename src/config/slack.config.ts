import { z } from 'zod'

const slack_config_schema = z.object({
  SLACK_BOT_TOKEN: z.string(),
  SLACK_APP_TOKEN: z.string(),
  SLACK_CHANNEL_ID: z.string(),
})

export const slack_config = slack_config_schema.parse({
  SLACK_BOT_TOKEN: process.env.SLACK_BOT_TOKEN,
  SLACK_APP_TOKEN: process.env.SLACK_APP_TOKEN,
  SLACK_CHANNEL_ID: process.env.SLACK_CHANNEL_ID,
}) 