Email Deliverability Playbook

Purpose
- Practical runbook to diagnose and improve transactional and marketing email deliverability.

Checklist
1. Authentication
   - Ensure SPF, DKIM, and DMARC are configured for sending domains.
   - Monitor DMARC reports for failed sources.

2. Sending Reputation
   - Use dedicated IPs for high-volume sending; warm up slowly.
   - Monitor bounce rates, complaint rates, and spam-trap hits.

3. Content Best Practices
   - Avoid spammy keywords; provide plain-text alternative; include unsubscribe link for marketing.
   - Keep templates lean and avoid tracking pixels in transactional emails unless necessary.

4. List Quality
   - Verify email addresses at collection time and use double opt-in for marketing lists.
   - Remove hard bounces and long-term inactivity (>180 days) from marketing lists.

5. Monitoring & Alerts
   - Track deliverability metrics: delivery rate, open rate, bounce rate, complaint rate.
   - Alert on sudden drops in delivery or spikes in bounces.

6. Debugging Steps
   - Check bounce codes and mail logs for cause.
   - Validate SPF/DKIM alignment; use tools like MXToolbox and DMARC analyzer.
   - Inspect email headers from recipient to confirm path.

7. Failover & Retry
   - Use exponential backoff for transient SMTP failures.
   - For critical transactional messages, retry on soft bounces; escalate persistent failures.

8. Provider Play
   - Evaluate ESPs for deliverability; consider switching if long-term reputation issues persist.

9. Privacy & Compliance
   - Respect unsubscribe and suppression lists; honor legal requirements (CAN-SPAM, GDPR).

Owner
- Product + Ops maintain sending domain configuration; SRE owns alerts and DNS records.