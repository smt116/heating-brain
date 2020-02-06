import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"
import Chart from "chart.js"

document.charts = {}
let Hooks = {}

const expectedValuesColor = "rgba(255, 220,0, 0.5)"
const pipeInColor = "#7FDBFF"
const stateColor = "rgba(1, 255, 112, 0.25)"
const valueColor = "#85144B"

Hooks.ChartHook = {
  mounted() {
    const chart = document.querySelectorAll(`#${this.el.id} .chartContainer`)[0]
    const label = this.el.dataset.chartLabel
    const data = JSON.parse(this.el.dataset.data)

    document.charts[this.el.id] = new Chart(chart, {
      data: {
        datasets: [{
          backgroundColor: valueColor,
          borderColor: valueColor,
          data: data.values,
          fill: false,
          label: "Temperatura",
          pointHoverRadius: 3,
          pointRadius: 2,
          spanGaps: true,
          type: "line",
          yAxisID: "temp",
        }, {
          backgroundColor: expectedValuesColor,
          borderColor: expectedValuesColor,
          data: data.expected_values,
          fill: false,
          label: "Oczekiawana temperatura",
          pointHoverRadius: 1,
          pointRadius: 1,
          spanGaps: false,
          type: "line",
          yAxisID: "temp",
        }, {
          backgroundColor: stateColor,
          borderColor: stateColor,
          data: data.states,
          fill: true,
          label: "Ogrzewanie strefy",
          pointHoverRadius: 2,
          spanGaps: true,
          pointRadius: 1,
          steppedLine: "before",
          type: "line",
          yAxisID: "state",
        }, {
          backgroundColor: pipeInColor,
          borderColor: pipeInColor,
          data: data.pipe_in,
          fill: false,
          label: "Temperatura wody na wejściu",
          pointHoverRadius: 1,
          pointRadius: 1,
          spanGaps: false,
          type: "line",
          yAxisID: "temp",
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
              labelString: "Ogrzwanie",
            },
            ticks: {
              min: 0,
              max: 1,
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

    const pipeIn = JSON.parse(this.el.dataset.currentPipeIn)
    if (pipeIn !== null) {
      const pipeInDuplication = chart.data.datasets[3].data.find(p => p.x === pipeIn.timestamp)

      if(pipeInDuplication === undefined) {
        chart.data.datasets[3].data.push({
          x: pipeIn.timestamp,
          y: pipeIn.value,
        })
      }
    }

    const state = JSON.parse(this.el.dataset.currentState)
    if (state !== null) {
      const stateDuplication = chart.data.datasets[2].data.find(p => p.x === state.timestamp)

      if(stateDuplication === undefined) {
        chart.data.datasets[2].data.push({
          x: state.timestamp,
          y: state.value ? 1 : 0
        })
      } else {
        // Make sure that the line does not end in the middle of the chart if the
        // relay was not updated for a while.
        const data = chart.data.datasets[2].data
        const state = data[data.length - 1]

        chart.data.datasets[2].data.push({
          ...state,
          x: measurement.timestamp,
        })
      }
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
