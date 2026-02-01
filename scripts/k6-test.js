import { check, sleep } from 'k6'
import http from 'k6/http'

export let options = {
  // Duration is set via environment variable K6_DURATION
  duration: __ENV.K6_DURATION || '120s',

  // VUs are set via environment variable K6_VUS
  vus: parseInt(__ENV.K6_VUS) || 1
}

export default function () {
  const target = __ENV.TARGET_URL || 'http://apache'

  const response = http.get(target)

  check(response, {
    'status is 200': r => r.status === 200,
    'response time < 500ms': r => r.timings.duration < 500
  })

  // Think time - simulate user reading/processing time
  const thinkTime = parseFloat(__ENV.K6_THINK_TIME || '0')
  if (thinkTime > 0) {
    sleep(thinkTime)
  }
}
