import { Controller } from "@hotwired/stimulus"
import "chart.js"

const Chart = window.Chart

export default class extends Controller {
  static targets = ["chart", "skeleton"]

  connect() {
    this.charts = this.chartTargets.map((canvas) => this.buildChart(canvas))
    this.skeletonTargets.forEach((item) => item.hidden = true)
    this.chartTargets.forEach((item) => item.hidden = false)
  }

  disconnect() {
    this.charts?.forEach((chart) => chart.destroy())
  }

  buildChart(canvas) {
    const kind = canvas.dataset.kind
    const labels = JSON.parse(canvas.dataset.labels)
    const values = JSON.parse(canvas.dataset.values)
    const type = kind === "donut" ? "doughnut" : (kind === "line" ? "line" : "bar")
    const palette = ["#2563eb", "#10b981", "#f7941d", "#dc2626", "#8b5cf6", "#0891b2"]

    return new Chart(canvas, {
      type,
      data: { labels, datasets: [{ data: values, backgroundColor: type === "doughnut" ? palette : palette[0],
        borderColor: type === "line" ? palette[2] : "transparent", borderWidth: type === "line" ? 3 : 0,
        tension: 0.3, fill: type === "line" }] },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: canvas.dataset.horizontal === "true" ? "y" : "x",
        plugins: { legend: { display: type === "doughnut", position: "bottom" } },
        onClick: (_event, elements) => {
          if (!canvas.dataset.url) return
          const url = new URL(canvas.dataset.url, window.location.origin)
          const field = canvas.dataset.filterField
          const values = JSON.parse(canvas.dataset.filterValues || "[]")
          const value = elements.length ? values[elements[0].index] : null
          if (field && value) url.searchParams.set(`filter[${field}]`, value)
          window.Turbo.visit(`${url.pathname}${url.search}`)
        }
      }
    })
  }
}
