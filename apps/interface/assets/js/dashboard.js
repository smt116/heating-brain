import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"
import Chart from "chart.js"
import colors from "./colors.js"

document.charts = {}
let Hooks = {}

Hooks.ChartHook = {
  mounted() {
    const chart = document.querySelectorAll(`#${this.el.id} .chartContainer`)[0]
    const dataset = JSON.parse(this.el.dataset.dataset)
    const label = this.el.dataset.label
    const labels = JSON.parse(this.el.dataset.labels)

    document.charts[this.el.id] = new Chart(chart, {
      type: "line",
      data: {
        datasets: [{
          backgroundColor: colors[label],
          borderColor: colors[label],
          data: dataset,
          fill: false,
          label: label,
          pointHoverRadius: 2,
          pointRadius: 1,
          spanGaps: true,
        }],
        labels: labels
      },
      options: {}
    })
  },
  updated() {
    const chart = document.charts[this.el.id]
    const label = this.el.dataset.currentLabel
    const value = this.el.dataset.currentValue

    chart.data.labels.push(label)
    chart.data.datasets.forEach((dataset) => {
        dataset.data.push(value)
    })
    chart.update()
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

liveSocket.connect()
