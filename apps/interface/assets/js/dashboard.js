import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"
import Chart from "chart.js"
import colors from "./colors.js"

document.charts = {}
let Hooks = {}

const expectedValuesBackgroundColor = "rgba(255, 220,0, 0.5)"
const stateBackgroundColor = "rgba(1, 255, 112, 0.25)"

Hooks.ChartHook = {
  mounted() {
    const chart = document.querySelectorAll(`#${this.el.id} .chartContainer`)[0]
    const label = this.el.dataset.chartLabel
    const data = JSON.parse(this.el.dataset.data)

    document.charts[this.el.id] = new Chart(chart, {
      data: {
        datasets: [{
          backgroundColor: colors[this.el.id],
          borderColor: colors[this.el.id],
          data: data.values,
          fill: false,
          label: "Temperatura",
          pointHoverRadius: 2,
          pointRadius: 1,
          spanGaps: true,
          type: "line",
          yAxisID: "temp",
        }, {
          backgroundColor: expectedValuesBackgroundColor,
          borderColor: expectedValuesBackgroundColor,
          data: data.expected_values,
          fill: false,
          label: "Oczekiawana temperatura",
          pointHoverRadius: 2,
          pointRadius: 1,
          spanGaps: false,
          type: "line",
          yAxisID: "temp",
        }, {
          backgroundColor: stateBackgroundColor,
          borderColor: stateBackgroundColor,
          data: data.states,
          fill: true,
          label: "Ogrzewanie",
          lineTension: 0,
          pointHoverRadius: 2,
          pointRadius: 1,
          spanGaps: true,
          type: "line",
          yAxisID: "state",
        }],
      },
      options: {
        responsive: true,
        scales: {
          xAxes: [{
            type: "time",
            time: {
              displayFormats: {
                second: "H:mm:ss"
              }
            }
          }],
          yAxes: [{
            id: "temp",
            scaleLabel: {
              labelString: "Temperatura"
            },
            ticks: {
              beginAtZero: true,
              callback: (value) => `${value}°C`
            }
          }, {
            id: "state",
            display: false,
            scaleLabel: {
              display: false,
              labelString: "Ogrzwanie"
            }
          }]
        },
        title: {
          display: true,
          text: label,
        }
      }
    })
  },
  updated() {
    const chart = document.charts[this.el.id]

    const measurement = JSON.parse(this.el.dataset.currentMeasurement)
    const valueDuplication = chart.data.datasets[0].data.find(p => p.x === measurement.timestamp)

    if(valueDuplication === undefined) {
      chart.options.title.text = this.el.dataset.chartLabel
      chart.data.datasets[0].data.push({
        x: measurement.timestamp,
        y: measurement.value,
      })

      if (measurement.expected_value) {
        chart.data.datasets[1].data.push({
          x: measurement.timestamp,
          y: measurement.expected_value
        })
      }
    }

    const state = JSON.parse(this.el.dataset.currentState)
    const stateDuplication = chart.data.datasets[2].data.find(p => p.x === state.timestamp)

    if(stateDuplication === undefined) {
      chart.data.datasets[2].data.push({
        x: state.timestamp,
        y: state.value ? 1 : 0
      })
    }

    chart.update()
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

liveSocket.connect()
