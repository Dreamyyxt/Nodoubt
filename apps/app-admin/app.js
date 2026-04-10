const API_BASE = "http://127.0.0.1:3000/api/v1/admin";

const buttons = document.querySelectorAll(".nav-item");
const panels = document.querySelectorAll(".panel");
const title = document.getElementById("panel-title");
const description = document.getElementById("panel-description");
const refreshButton = document.getElementById("refresh-button");
const statusBanner = document.getElementById("status-banner");
const opportunitiesBulkFeatureButton = document.getElementById("opportunities-bulk-feature");
const opportunitiesBulkUnfeatureButton = document.getElementById("opportunities-bulk-unfeature");

const panelDescriptions = {
  overview: "这里直接读取开发环境数据，用来演示审核、风控和运营观察面板。",
  listings: "先看待审核发布，帮助你判断当前广场里哪些内容需要人工把关。",
  reports: "举报会按最新时间排在前面，用于展示平台的风控入口。",
  orders: "这里聚焦交易流转，方便看待支付、待接单和待确认这些阶段。",
  users: "用户巡检面板帮助你快速识别核心活跃用户和测试链路。",
};

const state = {
  overview: null,
  opportunities: [],
  listings: [],
  reports: [],
  orders: [],
  users: [],
};

const filters = {
  listingsSearch: "",
  opportunities: "ALL",
  opportunitiesSearch: "",
  opportunitiesCity: "ALL",
  opportunitiesBudget: "ALL",
  reportsSearch: "",
  reportsStatus: "ALL",
};

const selectedOpportunityIds = new Set();

buttons.forEach((button) => {
  button.addEventListener("click", () => {
    const target = button.dataset.panel;

    buttons.forEach((item) => item.classList.remove("is-active"));
    panels.forEach((panel) => panel.classList.remove("is-active"));

    button.classList.add("is-active");
    document.getElementById(target)?.classList.add("is-active");
    title.textContent = button.textContent ?? "总览";
    description.textContent = panelDescriptions[target] ?? "";
  });
});

refreshButton.addEventListener("click", () => {
  loadAll();
});

document.getElementById("listings-search")?.addEventListener("input", (event) => {
  filters.listingsSearch = event.target.value.trim().toLowerCase();
  renderListings();
});

document.getElementById("opportunities-filter")?.addEventListener("change", (event) => {
  filters.opportunities = event.target.value;
  loadAll();
});

document.getElementById("opportunities-search")?.addEventListener("input", (event) => {
  filters.opportunitiesSearch = event.target.value.trim().toLowerCase();
  renderOverview();
});

document.getElementById("opportunities-city-filter")?.addEventListener("change", (event) => {
  filters.opportunitiesCity = event.target.value;
  renderOverview();
});

document.getElementById("opportunities-budget-filter")?.addEventListener("change", (event) => {
  filters.opportunitiesBudget = event.target.value;
  renderOverview();
});

document.getElementById("reports-search")?.addEventListener("input", (event) => {
  filters.reportsSearch = event.target.value.trim().toLowerCase();
  renderReports();
});

document.getElementById("reports-status-filter")?.addEventListener("change", (event) => {
  filters.reportsStatus = event.target.value;
  renderReports();
});

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    loadAll();
  }
});

async function fetchJson(path) {
  const response = await fetch(`${API_BASE}${path}`);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  const payload = await response.json();
  return payload.data;
}

async function postJson(path, body) {
  const response = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(payload.message || `HTTP ${response.status}`);
  }

  return payload.data;
}

async function loadAll() {
  renderLoadingState();
  showStatus("正在拉取最新后台数据...", "info");

  try {
    const [overview, opportunities, listings, reports, orders, users] = await Promise.all([
      fetchJson("/overview"),
      fetchJson(`/opportunities?filter=${encodeURIComponent(filters.opportunities)}`),
      fetchJson("/listings?status=pending"),
      fetchJson("/reports"),
      fetchJson("/orders"),
      fetchJson("/users"),
    ]);

    state.overview = overview;
    state.opportunities = opportunities;
    state.listings = listings;
    state.reports = reports;
    state.orders = orders;
    state.users = users;
    cleanupSelectedOpportunities();

    renderOverview();
    renderListings();
    renderReports();
    renderOrders();
    renderUsers();
    showStatus("后台数据已刷新。", "success");
  } catch (error) {
    console.error(error);
    renderErrorState(error.message);
    showStatus(`加载失败：${error.message}`, "error");
  }
}

function renderLoadingState() {
  document.getElementById("overview-metrics").innerHTML = `
    ${metricCard("待审核发布", "...", "正在同步发布数据", "listing")}
    ${metricCard("进行中订单", "...", "正在同步订单数据", "order")}
    ${metricCard("待处理举报", "...", "正在同步风控数据", "report")}
    ${metricCard("平台用户", "...", "正在同步用户数据", "user")}
    ${metricCard("样本 GMV", "...", "正在估算成交体量", "gmv")}
    ${metricCard("预估平台费", "...", "正在估算前期抽佣", "revenue")}
  `;
  document.getElementById("overview-listings").innerHTML = emptyBlock("正在加载最新发布...");
  document.getElementById("overview-orders").innerHTML = emptyBlock("正在加载最新订单...");
  document.getElementById("overview-map").innerHTML = emptyBlock("正在加载城市热力...");
  document.getElementById("overview-timeline").innerHTML = emptyBlock("正在加载最近流转...");
  document.getElementById("overview-opportunities").innerHTML = emptyBlock("正在加载高价值任务...");
  document.getElementById("listings-body").innerHTML = tableEmpty("正在加载待审核发布...");
  document.getElementById("reports-body").innerHTML = tableEmpty("正在加载举报数据...");
  document.getElementById("orders-body").innerHTML = tableEmpty("正在加载订单数据...");
  document.getElementById("users-body").innerHTML = tableEmpty("正在加载用户数据...");
}

function renderErrorState(message) {
  document.getElementById("overview-metrics").innerHTML = `
    ${metricCard("待审核发布", "-", "接口暂时不可用", "listing")}
    ${metricCard("进行中订单", "-", "接口暂时不可用", "order")}
    ${metricCard("待处理举报", "-", "接口暂时不可用", "report")}
    ${metricCard("平台用户", "-", "接口暂时不可用", "user")}
    ${metricCard("样本 GMV", "-", "接口暂时不可用", "gmv")}
    ${metricCard("预估平台费", "-", "接口暂时不可用", "revenue")}
  `;
  document.getElementById("overview-listings").innerHTML = emptyBlock(`加载失败：${escapeHtml(message)}`);
  document.getElementById("overview-orders").innerHTML = emptyBlock("请先确认 app-server 已启动，并刷新后台页面。");
  document.getElementById("overview-map").innerHTML = emptyBlock("城市热力暂时不可用。");
  document.getElementById("overview-timeline").innerHTML = emptyBlock("最近流转暂时不可用。");
  document.getElementById("overview-opportunities").innerHTML = emptyBlock("高价值任务池暂时不可用。");
  document.getElementById("listings-body").innerHTML = tableEmpty(`加载失败：${escapeHtml(message)}`);
  document.getElementById("reports-body").innerHTML = tableEmpty("请先确认后台接口可访问。");
  document.getElementById("orders-body").innerHTML = tableEmpty("请先确认后台接口可访问。");
  document.getElementById("users-body").innerHTML = tableEmpty("请先确认后台接口可访问。");
}

function renderOverview() {
  const container = document.getElementById("overview-metrics");
  const listingsContainer = document.getElementById("overview-listings");
  const ordersContainer = document.getElementById("overview-orders");
  const mapContainer = document.getElementById("overview-map");
  const timelineContainer = document.getElementById("overview-timeline");
  const opportunitiesContainer = document.getElementById("overview-opportunities");
  const overview = state.overview;

  if (!overview) {
    return;
  }

  container.innerHTML = [
    metricCard("待审核发布", overview.metrics.pendingListings, "盯住广场入口", "listing"),
    metricCard("进行中订单", overview.metrics.activeOrders, "盯住成交推进", "order"),
    metricCard("待处理举报", overview.metrics.pendingReports, "盯住风控风险", "report"),
    metricCard("平台用户", overview.metrics.totalUsers, "盯住活跃供给", "user"),
    metricCard("样本 GMV", `¥${formatMoney(overview.metrics.grossMerchandiseValue)}`, "先验证真实成交体量", "gmv"),
    metricCard("预估平台费", `¥${formatMoney(overview.metrics.estimatedRevenue)}`, "按 5% 种子阶段抽佣估算", "revenue"),
  ].join("");

  listingsContainer.innerHTML = overview.latestListings.length
    ? overview.latestListings
        .map(
          (item) => `
            <article class="mini-item">
              <div>
                <strong>${escapeHtml(item.title)}</strong>
                <p>${escapeHtml(item.publisherName)} · ${labelListingType(item.listingType)} · ${formatDate(item.createdAt)}</p>
              </div>
              <span class="pill ${pillClass(item.auditStatus === "PENDING" ? "warn" : "good")}">${labelAuditStatus(item.auditStatus)}</span>
            </article>
          `,
        )
        .join("")
    : emptyBlock("还没有最新发布");

  ordersContainer.innerHTML = overview.latestOrders.length
    ? overview.latestOrders
        .map(
          (item) => `
            <article class="mini-item">
              <div>
                <strong>${escapeHtml(item.title)}</strong>
                <p>¥${formatMoney(item.amountTotal)} · ${formatDate(item.createdAt)}</p>
              </div>
              <span class="pill ${pillClass(orderTone(item.orderStatus))}">${labelOrderStatus(item.orderStatus)}</span>
            </article>
          `,
        )
        .join("")
    : emptyBlock("还没有最新订单");

  mapContainer.innerHTML = overview.cityActivity.length
    ? `
        <div class="map-canvas">
          <div class="map-grid"></div>
          ${overview.cityActivity
            .map((item, index) => {
              const positions = [
                "top:18%;left:58%;",
                "top:36%;left:32%;",
                "top:58%;left:64%;",
                "top:62%;left:22%;",
                "top:24%;left:20%;",
              ];
              const intensity = item.listingCount + item.orderCount;
              return `
                <button class="map-pin" style="${positions[index] || positions[0]}" title="${escapeHtml(labelCity(item.cityCode))}">
                  <span class="pin-dot" style="width:${18 + intensity * 4}px;height:${18 + intensity * 4}px"></span>
                  <span class="pin-label">${escapeHtml(labelCity(item.cityCode))}</span>
                  <span class="pin-meta">${item.listingCount} 发布 / ${item.orderCount} 订单</span>
                </button>
              `;
            })
            .join("")}
        </div>
      `
    : emptyBlock("还没有足够的城市活动数据");

  timelineContainer.innerHTML = overview.activityTimeline.length
    ? overview.activityTimeline
        .map(
          (item) => `
            <article class="timeline-item">
              <div class="timeline-icon">${iconBadge(iconForTimeline(item.eventType))}</div>
              <div class="timeline-content">
                <strong>${escapeHtml(item.title)}</strong>
                <p>${escapeHtml(item.detail)}</p>
                <span>${escapeHtml(labelCity(item.cityCode))} · ${formatDate(item.createdAt)}</span>
              </div>
            </article>
          `,
        )
        .join("")
    : emptyBlock("还没有最近流转记录");

  renderOpportunityCityOptions();

  const visibleOpportunities = state.opportunities.filter((item) => {
    const haystack = `${item.title} ${item.publisherName} ${labelCity(item.cityCode || item.publisherCityCode)} ${item.locationText || ""}`.toLowerCase();
    const searchMatch = !filters.opportunitiesSearch || haystack.includes(filters.opportunitiesSearch);
    const cityCode = item.cityCode || item.publisherCityCode || "unknown";
    const cityMatch = filters.opportunitiesCity === "ALL" || cityCode === filters.opportunitiesCity;
    const budget = Number(item.budgetAmount || 0);
    const budgetMatch =
      filters.opportunitiesBudget === "ALL"
      || (filters.opportunitiesBudget === "HIGH" && budget >= 500)
      || (filters.opportunitiesBudget === "MID" && budget >= 300 && budget < 500)
      || (filters.opportunitiesBudget === "LOW" && budget < 300);
    return searchMatch && cityMatch && budgetMatch;
  });

  opportunitiesContainer.innerHTML = visibleOpportunities.length
    ? visibleOpportunities
        .slice(0, 8)
        .map(
          (item) => `
            <article class="opportunity-item ${selectedOpportunityIds.has(item.id) ? "is-selected" : ""}">
              <div class="opportunity-main">
                <label class="opportunity-select">
                  <input type="checkbox" data-action="toggle-opportunity" data-id="${escapeHtml(item.id)}" ${selectedOpportunityIds.has(item.id) ? "checked" : ""} />
                  <span>加入批量操作</span>
                </label>
                <div class="opportunity-topline">
                  <strong>${escapeHtml(item.title)}</strong>
                  <span class="pill ${pillClass(item.isFeatured ? "good" : item.isUrgent ? "warn" : "info")}">${item.isFeatured ? "已推荐" : item.isUrgent ? "加急" : "可运营"}</span>
                </div>
                <p>${escapeHtml(item.publisherName)} · ${escapeHtml(labelCity(item.cityCode || item.publisherCityCode))} · ¥${formatMoney(item.budgetAmount)}</p>
                <div class="tag-row">
                  ${(item.reasons || []).map((reason) => `<span class="mini-tag">${escapeHtml(reason)}</span>`).join("")}
                </div>
                ${item.opsNote ? `<p class="opportunity-note">${escapeHtml(item.opsNote)}</p>` : ""}
              </div>
              <div class="opportunity-side">
                <span>${escapeHtml(item.conversionStage || "待人工推动")}</span>
                <strong>¥${formatMoney(item.estimatedServiceFee)}</strong>
                <small>P${item.featuredPriority || 0} · ${item.applicationCount} 申请 / ${item.orderCount} 订单</small>
                ${item.featuredUntil ? `<small>剩余 ${Math.max(0, Number(item.featuredDaysRemaining || 0))} 天 · 到期：${formatDate(item.featuredUntil)}</small>` : `<small>未设置推荐时效</small>`}
                <div class="row-actions opportunity-actions">
                  ${
                    item.isFeatured
                      ? `<button class="table-action" data-action="unfeature-listing" data-id="${escapeHtml(item.id)}">取消推荐</button>`
                      : `<button class="table-action is-primary" data-action="feature-listing" data-id="${escapeHtml(item.id)}">标记推荐</button>`
                  }
                </div>
              </div>
            </article>
          `,
        )
        .join("")
    : emptyBlock("还没有进入运营视野的高价值任务");

  document.getElementById("opportunities-count").textContent = `${visibleOpportunities.length} 条`;
  updateOpportunityBulkButtons();
}

function renderOpportunityCityOptions() {
  const select = document.getElementById("opportunities-city-filter");
  if (!(select instanceof HTMLSelectElement)) {
    return;
  }
  const currentValue = filters.opportunitiesCity;
  const cities = [...new Set(state.opportunities.map((item) => item.cityCode || item.publisherCityCode).filter(Boolean))];
  select.innerHTML = [
    '<option value="ALL">全部城市</option>',
    ...cities
      .sort((a, b) => labelCity(a).localeCompare(labelCity(b), "zh-CN"))
      .map((cityCode) => `<option value="${escapeHtml(cityCode)}">${escapeHtml(labelCity(cityCode))}</option>`),
  ].join("");
  select.value = cities.includes(currentValue) || currentValue === "ALL" ? currentValue : "ALL";
  filters.opportunitiesCity = select.value;
}

function renderListings() {
  const body = document.getElementById("listings-body");
  const items = state.listings.filter((item) => {
    if (!filters.listingsSearch) return true;
    const haystack = `${item.title} ${item.publisherName}`.toLowerCase();
    return haystack.includes(filters.listingsSearch);
  });
  document.getElementById("listings-count").textContent = `${items.length} 条`;

  body.innerHTML = items.length
    ? items
        .map(
          (item) => `
            <tr>
              <td>
                <div class="primary-cell">
                  <strong>${escapeHtml(item.title)}</strong>
                  <span>${item.isUrgent ? "加急" : "常规"} · ${formatDate(item.createdAt)}</span>
                </div>
              </td>
              <td>${labelListingType(item.listingType)}</td>
              <td>${escapeHtml(item.publisherName)}</td>
              <td>${escapeHtml(item.cityCode || item.publisherCityCode || "-")}</td>
              <td>${item.applicationCount}</td>
              <td><span class="pill ${pillClass("warn")}">${labelAuditStatus(item.auditStatus)}</span></td>
              <td>
                <div class="row-actions">
                  <button class="table-action is-primary" data-action="approve-listing" data-id="${escapeHtml(item.id)}">通过</button>
                  <button class="table-action" data-action="reject-listing" data-id="${escapeHtml(item.id)}">驳回</button>
                </div>
              </td>
            </tr>
          `,
        )
        .join("")
    : tableEmpty("当前没有待审核发布", 7);
}

function renderReports() {
  const body = document.getElementById("reports-body");
  const items = state.reports.filter((item) => {
    const statusMatch = filters.reportsStatus === "ALL" || item.status === filters.reportsStatus;
    const searchMatch = !filters.reportsSearch
      || `${item.reasonCode} ${item.reporterName} ${item.targetId} ${item.targetType}`
          .toLowerCase()
          .includes(filters.reportsSearch);
    return statusMatch && searchMatch;
  });
  document.getElementById("reports-count").textContent = `${items.length} 条`;

  body.innerHTML = items.length
    ? items
        .map(
          (item) => `
            <tr>
              <td>${escapeHtml(item.reporterName)}</td>
              <td>${escapeHtml(item.targetType)}</td>
              <td class="mono">${escapeHtml(item.targetId)}</td>
              <td>${escapeHtml(item.reasonCode)}</td>
              <td><span class="pill ${pillClass(reportTone(item.status))}">${labelReportStatus(item.status)}</span></td>
              <td>${escapeHtml(item.reviewResult || item.description || "-")}</td>
              <td>${formatDate(item.createdAt)}</td>
              <td>
                ${
                  item.status === "PENDING"
                    ? `<div class="row-actions">
                        <button class="table-action is-primary" data-action="resolve-report" data-id="${escapeHtml(item.id)}">已处理</button>
                        <button class="table-action" data-action="reject-report" data-id="${escapeHtml(item.id)}">驳回举报</button>
                      </div>`
                    : `<span class="pill ${pillClass("info")}">已结案</span>`
                }
              </td>
            </tr>
          `,
        )
        .join("")
    : tableEmpty("当前没有举报记录", 8);
}

function renderOrders() {
  const body = document.getElementById("orders-body");
  document.getElementById("orders-count").textContent = `${state.orders.length} 条`;

  body.innerHTML = state.orders.length
    ? state.orders
        .map(
          (item) => `
            <tr>
              <td>
                <div class="primary-cell">
                  <strong>${escapeHtml(item.title)}</strong>
                  <span class="mono">${escapeHtml(item.id)}</span>
                </div>
              </td>
              <td>${escapeHtml(item.buyerName)} / ${escapeHtml(item.sellerName)}</td>
              <td>${labelListingType(item.listingType)}</td>
              <td>¥${formatMoney(item.amountTotal)}</td>
              <td><span class="pill ${pillClass(orderTone(item.orderStatus))}">${labelOrderStatus(item.orderStatus)}</span></td>
              <td>${formatDate(item.createdAt)}</td>
            </tr>
          `,
        )
        .join("")
    : tableEmpty("当前没有订单记录", 6);
}

function renderUsers() {
  const body = document.getElementById("users-body");
  document.getElementById("users-count").textContent = `${state.users.length} 位`;

  body.innerHTML = state.users.length
    ? state.users
        .map(
          (item) => `
            <tr>
              <td>
                <div class="primary-cell">
                  <strong>${escapeHtml(item.nickname)}</strong>
                  <span class="mono">${escapeHtml(item.id)}</span>
                </div>
              </td>
              <td>${escapeHtml(item.phone)}</td>
              <td>${escapeHtml(item.cityCode || "-")}</td>
              <td>${item.creditScore}</td>
              <td>${item.publishedListings} / ${item.applications}</td>
              <td>${item.boughtOrders} / ${item.soldOrders}</td>
            </tr>
          `,
        )
        .join("")
    : tableEmpty("当前没有用户记录", 6);
}

function metricCard(label, value, description, icon) {
  return `
    <article class="metric-card">
      <div class="metric-icon">${iconBadge(icon)}</div>
      <span>${label}</span>
      <strong>${value}</strong>
      <p>${description}</p>
    </article>
  `;
}

function emptyBlock(text) {
  return `<div class="empty-block">${text}</div>`;
}

function tableEmpty(text, colspan = 6) {
  return `<tr><td colspan="${colspan}"><div class="empty-block table-empty">${text}</div></td></tr>`;
}

function pillClass(tone) {
  return `pill-${tone}`;
}

function iconBadge(type) {
  const icons = {
    listing:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5z" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M8 9h8M8 13h8M8 17h5" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    order:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 4.5h12A1.5 1.5 0 0 1 19.5 6v12A1.5 1.5 0 0 1 18 19.5H6A1.5 1.5 0 0 1 4.5 18V6A1.5 1.5 0 0 1 6 4.5z" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M8 8h8M8 12h8M8 16h4" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    report:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4l8 14H4z" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M12 9v4m0 3h.01" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    user:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 12a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM5 19a7 7 0 0 1 14 0" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    gmv:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4.5 17.5 9 12l3 3 7.5-8" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="M16 7h3.5v3.5" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    revenue:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4.5v15m3.5-11.5c0-1.38-1.57-2.5-3.5-2.5S8.5 6.62 8.5 8 10.07 10.5 12 10.5s3.5 1.12 3.5 2.5-1.57 2.5-3.5 2.5-3.5-1.12-3.5-2.5" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    timelineListing:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 5h12v14H6z" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M9 9h6M9 13h6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    timelineOrder:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 7h10v10H7z" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M9 12h6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    timelineReport:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v8" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><circle cx="12" cy="17" r="1" fill="currentColor"/><path d="M12 3 4 19h16z" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/></svg>',
  };

  return icons[type] || icons.listing;
}

function iconForTimeline(eventType) {
  if (eventType === "order_updated") return "timelineOrder";
  if (eventType === "report_created") return "timelineReport";
  return "timelineListing";
}

function orderTone(status) {
  if (status === "COMPLETED") return "good";
  if (status === "PENDING_CONFIRMATION" || status === "IN_PROGRESS") return "info";
  if (status === "PENDING_ACCEPT") return "warn";
  return "bad";
}

function labelListingType(type) {
  return type === "EXCHANGE" ? "交换" : "任务";
}

function labelAuditStatus(status) {
  if (status === "PENDING") return "待审核";
  if (status === "APPROVED") return "已通过";
  if (status === "REJECTED") return "已驳回";
  return status;
}

function labelOrderStatus(status) {
  const map = {
    PENDING_PAYMENT: "待支付",
    PENDING_ACCEPT: "待接单",
    IN_PROGRESS: "进行中",
    PENDING_CONFIRMATION: "待确认",
    COMPLETED: "已完成",
  };

  return map[status] || status;
}

function labelReportStatus(status) {
  if (status === "PENDING") return "待处理";
  if (status === "PROCESSING") return "处理中";
  if (status === "RESOLVED") return "已处理";
  if (status === "REJECTED") return "已驳回";
  return status;
}

function reportTone(status) {
  if (status === "PENDING") return "bad";
  if (status === "RESOLVED") return "good";
  if (status === "REJECTED") return "muted";
  return "info";
}

function labelCity(cityCode) {
  if (!cityCode || cityCode === "unknown") return "未知区域";
  if (cityCode === "shanghai") return "上海";
  if (cityCode === "beijing") return "北京";
  if (cityCode === "guangzhou") return "广州";
  if (cityCode === "shenzhen") return "深圳";
  return cityCode;
}

function formatMoney(value) {
  return Number(value || 0).toFixed(0);
}

function formatDate(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "-";
  }

  return `${date.getMonth() + 1}/${String(date.getDate()).padStart(2, "0")} ${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

function showStatus(message, tone) {
  statusBanner.hidden = false;
  statusBanner.textContent = message;
  statusBanner.className = `status-banner is-${tone}`;

  if (tone !== "error") {
    window.clearTimeout(showStatus.timer);
    showStatus.timer = window.setTimeout(() => {
      statusBanner.hidden = true;
    }, 2200);
  }
}

function escapeHtml(input) {
  return String(input)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function cleanupSelectedOpportunities() {
  const ids = new Set(state.opportunities.map((item) => item.id));
  for (const id of [...selectedOpportunityIds]) {
    if (!ids.has(id)) {
      selectedOpportunityIds.delete(id);
    }
  }
}

function updateOpportunityBulkButtons() {
  const count = selectedOpportunityIds.size;
  if (opportunitiesBulkFeatureButton) {
    opportunitiesBulkFeatureButton.disabled = count === 0;
    opportunitiesBulkFeatureButton.textContent = count === 0 ? "批量推荐" : `批量推荐 ${count} 条`;
  }
  if (opportunitiesBulkUnfeatureButton) {
    opportunitiesBulkUnfeatureButton.disabled = count === 0;
    opportunitiesBulkUnfeatureButton.textContent = count === 0 ? "批量取消" : `批量取消 ${count} 条`;
  }
}

async function batchFeatureSelected() {
  const ids = [...selectedOpportunityIds];
  if (!ids.length) return;
  const note = window.prompt("填写推荐理由（会同步到前台推荐任务展示）", "运营判断：有城市故事感，适合优先推动成交。");
  if (note === null) return;
  const priorityInput = window.prompt("设置推荐优先级（1-5，越高越靠前）", "3");
  if (priorityInput === null) return;
  const validDaysInput = window.prompt("设置推荐有效天数（1-30）", "7");
  if (validDaysInput === null) return;
  const priority = Number(priorityInput);
  const validDays = Number(validDaysInput);
  opportunitiesBulkFeatureButton?.setAttribute("disabled", "true");
  try {
    await Promise.all(
      ids.map((id) =>
        postJson(`/listings/${id}/feature`, {
          note: note || undefined,
          priority: Number.isFinite(priority) ? priority : undefined,
          validDays: Number.isFinite(validDays) ? validDays : undefined,
        }),
      ),
    );
    selectedOpportunityIds.clear();
    showStatus(`已批量推荐 ${ids.length} 条任务。`, "success");
    await loadAll();
  } catch (error) {
    showStatus(`批量推荐失败：${error.message}`, "error");
  } finally {
    opportunitiesBulkFeatureButton?.removeAttribute("disabled");
    updateOpportunityBulkButtons();
  }
}

async function batchUnfeatureSelected() {
  const ids = [...selectedOpportunityIds];
  if (!ids.length) return;
  opportunitiesBulkUnfeatureButton?.setAttribute("disabled", "true");
  try {
    await Promise.all(ids.map((id) => postJson(`/listings/${id}/unfeature`)));
    selectedOpportunityIds.clear();
    showStatus(`已批量取消 ${ids.length} 条推荐。`, "success");
    await loadAll();
  } catch (error) {
    showStatus(`批量取消失败：${error.message}`, "error");
  } finally {
    opportunitiesBulkUnfeatureButton?.removeAttribute("disabled");
    updateOpportunityBulkButtons();
  }
}

opportunitiesBulkFeatureButton?.addEventListener("click", () => {
  batchFeatureSelected();
});

opportunitiesBulkUnfeatureButton?.addEventListener("click", () => {
  batchUnfeatureSelected();
});

document.addEventListener("click", async (event) => {
  const target = event.target;
  if (!(target instanceof HTMLElement)) {
    return;
  }

  if (target.dataset.action === "approve-listing" && target.dataset.id) {
    target.setAttribute("disabled", "true");
    try {
      await postJson(`/listings/${target.dataset.id}/approve`);
      showStatus("发布已通过。", "success");
      await loadAll();
    } catch (error) {
      showStatus(`审核失败：${error.message}`, "error");
    } finally {
      target.removeAttribute("disabled");
    }
  }

  if (target.dataset.action === "toggle-opportunity" && target.dataset.id) {
    if (target instanceof HTMLInputElement && target.checked) {
      selectedOpportunityIds.add(target.dataset.id);
    } else {
      selectedOpportunityIds.delete(target.dataset.id);
    }
    renderOverview();
  }

  if (target.dataset.action === "feature-listing" && target.dataset.id) {
    const note = window.prompt("填写推荐理由（会同步到前台推荐任务展示）", "运营判断：预算高、地点明确、适合优先推动成交。");
    if (note === null) {
      return;
    }
    const priorityInput = window.prompt("设置推荐优先级（1-5，越高越靠前）", "3");
    if (priorityInput === null) {
      return;
    }
    const validDaysInput = window.prompt("设置推荐有效天数（1-30）", "7");
    if (validDaysInput === null) {
      return;
    }
    const priority = Number(priorityInput);
    const validDays = Number(validDaysInput);
    target.setAttribute("disabled", "true");
    try {
      await postJson(`/listings/${target.dataset.id}/feature`, {
        note: note || undefined,
        priority: Number.isFinite(priority) ? priority : undefined,
        validDays: Number.isFinite(validDays) ? validDays : undefined,
      });
      showStatus("任务已标记为推荐。", "success");
      await loadAll();
    } catch (error) {
      showStatus(`标记推荐失败：${error.message}`, "error");
    } finally {
      target.removeAttribute("disabled");
    }
  }

  if (target.dataset.action === "unfeature-listing" && target.dataset.id) {
    target.setAttribute("disabled", "true");
    try {
      await postJson(`/listings/${target.dataset.id}/unfeature`);
      showStatus("任务已取消推荐。", "success");
      await loadAll();
    } catch (error) {
      showStatus(`取消推荐失败：${error.message}`, "error");
    } finally {
      target.removeAttribute("disabled");
    }
  }

  if (target.dataset.action === "reject-listing" && target.dataset.id) {
    const reason = window.prompt("填写驳回原因（可选）", "信息不够清晰");
    if (reason === null) {
      return;
    }

    target.setAttribute("disabled", "true");
    try {
      await postJson(`/listings/${target.dataset.id}/reject`, { reason });
      showStatus("发布已驳回。", "success");
      await loadAll();
    } catch (error) {
      showStatus(`驳回失败：${error.message}`, "error");
    } finally {
      target.removeAttribute("disabled");
    }
  }

  if (target.dataset.action === "resolve-report" && target.dataset.id) {
    const result = window.prompt("填写处理结果（可选）", "已核实并完成处理");
    if (result === null) {
      return;
    }

    target.setAttribute("disabled", "true");
    try {
      await postJson(`/reports/${target.dataset.id}/resolve`, { result: result || undefined });
      showStatus("举报已标记为已处理。", "success");
      await loadAll();
    } catch (error) {
      showStatus(`处理举报失败：${error.message}`, "error");
    } finally {
      target.removeAttribute("disabled");
    }
  }

  if (target.dataset.action === "reject-report" && target.dataset.id) {
    const result = window.prompt("填写驳回说明（可选）", "举报不成立");
    if (result === null) {
      return;
    }

    target.setAttribute("disabled", "true");
    try {
      await postJson(`/reports/${target.dataset.id}/reject`, { result: result || undefined });
      showStatus("举报已驳回。", "success");
      await loadAll();
    } catch (error) {
      showStatus(`驳回举报失败：${error.message}`, "error");
    } finally {
      target.removeAttribute("disabled");
    }
  }
});

renderLoadingState();
loadAll();
window.setInterval(loadAll, 15000);
