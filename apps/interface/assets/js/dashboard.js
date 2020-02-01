import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"
import Chart from "chart.js"
import colors from "./colors.js"

document.charts = {}
let Hooks = {}

const expectedValuesBackgroundColor = "#FFDC00"

Hooks.ChartHook = {
  mounted() {
    const chart = document.querySelectorAll(`#${this.el.id} .chartContainer`)[0]
    const expectedValues = JSON.parse(this.el.dataset.expectedValues)
    const label = this.el.dataset.chartLabel
    const labels = JSON.parse(this.el.dataset.labels)
    const values = JSON.parse(this.el.dataset.values)

    document.charts[this.el.id] = new Chart(chart, {
      type: "line",
      data: {
        datasets: [{
          backgroundColor: colors[label],
          borderColor: colors[label],
          data: values,
          fill: false,
          label: "Value",
          pointHoverRadius: 2,
          pointRadius: 1,
          spanGaps: true,
        }, {
          backgroundColor: expectedValuesBackgroundColor,
          borderColor: expectedValuesBackgroundColor,
          data: expectedValues,
          fill: false,
          label: "Expected value",
          pointHoverRadius: 2,
          pointRadius: 1,
          spanGaps: false,
        }],
        labels: labels,
      },
      options: {
        responsive: true,
        title: {
          display: true,
          text: label,
        }
      }
    })
  },
  updated() {
    const chart = document.charts[this.el.id]
    const label = this.el.dataset.currentLabel

    if(chart.data.labels.indexOf(label) === -1) {
      const chartLabel = this.el.dataset.chartLabel
      const expectedValue = this.el.dataset.currentExpectedValue
      const value = this.el.dataset.currentValue

      chart.options.title.text = chartLabel
      chart.data.labels.push(label)
      chart.data.datasets[0].data.push(value)
      chart.data.datasets[1].data.push(expectedValue || NaN)

      chart.update()
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

liveSocket.connect()
