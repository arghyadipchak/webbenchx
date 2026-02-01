import { check, sleep } from 'k6'
import http from 'k6/http'

/* Env Configuration:
  TARGET_URL: The URL to send requests to (default: http://localhost)
  K6_DURATION: Duration of the test (default: 60s)
  K6_VUS: Number of virtual users (default: 1)
  K6_THINK_TIME: Think time between requests in seconds (default: 0)
*/

export let options = {
  duration: __ENV.K6_DURATION || '60s',
  vus: parseInt(__ENV.K6_VUS) || 1
}

export default function () {
  const target = __ENV.TARGET_URL || 'http://localhost'
  const response = http.get(target)

  check(response, { 'status is 200': r => r.status === 200 })

  const thinkTime = parseFloat(__ENV.K6_THINK_TIME || '0')
  if (thinkTime > 0) sleep(thinkTime)
}
