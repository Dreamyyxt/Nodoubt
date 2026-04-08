const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const cityPool = [
  { code: 'beijing', label: '北京', longitude: 116.4074, latitude: 39.9042 },
  { code: 'shanghai', label: '上海', longitude: 121.4737, latitude: 31.2304 },
  { code: 'guangzhou', label: '广州', longitude: 113.2644, latitude: 23.1291 },
  { code: 'shenzhen', label: '深圳', longitude: 114.0579, latitude: 22.5431 },
  { code: 'hangzhou', label: '杭州', longitude: 120.1551, latitude: 30.2741 },
  { code: 'chengdu', label: '成都', longitude: 104.0665, latitude: 30.5728 },
  { code: 'wuhan', label: '武汉', longitude: 114.3054, latitude: 30.5931 },
  { code: 'xian', label: '西安', longitude: 108.9398, latitude: 34.3416 },
  { code: 'nanjing', label: '南京', longitude: 118.7969, latitude: 32.0603 },
  { code: 'suzhou', label: '苏州', longitude: 120.5853, latitude: 31.2989 },
  { code: 'chongqing', label: '重庆', longitude: 106.5516, latitude: 29.5630 },
  { code: 'changsha', label: '长沙', longitude: 112.9388, latitude: 28.2282 },
  { code: 'qingdao', label: '青岛', longitude: 120.3826, latitude: 36.0671 },
  { code: 'xiamen', label: '厦门', longitude: 118.0894, latitude: 24.4798 },
  { code: 'tianjin', label: '天津', longitude: 117.2, latitude: 39.0842 },
];

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(list) {
  return list[randomInt(0, list.length - 1)];
}

function pickMany(list, count) {
  const source = [...list];
  const result = [];
  while (source.length > 0 && result.length < count) {
    result.push(source.splice(randomInt(0, source.length - 1), 1)[0]);
  }
  return result;
}

function randomRecentDate() {
  const now = Date.now();
  const daysBack = randomInt(0, 18);
  const hoursBack = randomInt(0, 23);
  return new Date(now - (daysBack * 24 + hoursBack) * 60 * 60 * 1000);
}

async function resetOrderData() {
  await prisma.review.deleteMany({});
  await prisma.refund.deleteMany({});
  await prisma.payment.deleteMany({});
  await prisma.orderEvent.deleteMany({});
  await prisma.chatMember.deleteMany({
    where: { chat: { orderId: { not: null } } },
  });
  await prisma.message.deleteMany({
    where: { chat: { orderId: { not: null } } },
  });
  await prisma.chat.deleteMany({
    where: { orderId: { not: null } },
  });
  await prisma.order.deleteMany({});

  await prisma.application.deleteMany({
    where: {
      OR: [
        { id: { startsWith: 'seed_order_application_' } },
        { handledBy: 'seed-order-bot' },
      ],
    },
  });

  await prisma.listing.updateMany({
    where: {
      OR: [
        { status: 'MATCHED' },
        { status: 'IN_PROGRESS' },
        { status: 'COMPLETED' },
      ],
    },
    data: {
      status: 'PUBLISHED',
      acceptedApplicationId: null,
    },
  });

  const listings = await prisma.listing.findMany({
    where: {
      auditStatus: 'APPROVED',
      status: 'PUBLISHED',
      longitude: { not: null },
      latitude: { not: null },
      deletedAt: null,
    },
    select: {
      id: true,
      publisherId: true,
      listingType: true,
      budgetAmount: true,
      cityCode: true,
      longitude: true,
      latitude: true,
    },
    orderBy: { createdAt: 'desc' },
    take: 90,
  });

  const users = await prisma.user.findMany({
    where: { deletedAt: null },
    select: {
      id: true,
      cityCode: true,
    },
  });

  const chosenListings = pickMany(listings, Math.min(50, listings.length));
  const statuses = [
    'PENDING_PAYMENT',
    'PENDING_ACCEPT',
    'IN_PROGRESS',
    'PENDING_CONFIRMATION',
    'COMPLETED',
  ];

  let createdOrders = 0;

  for (const listing of chosenListings) {
    const sellerCandidates = users.filter((user) => user.id !== listing.publisherId);
    if (!sellerCandidates.length) {
      continue;
    }

    const applicant = pick(sellerCandidates);
    const selectedStatus = pick(statuses);
    const createdAt = randomRecentDate();
    const city = cityPool.find((item) => item.code === listing.cityCode) ?? pick(cityPool);

    const quotedPrice =
      listing.listingType === 'TASK'
        ? Number(listing.budgetAmount ?? randomInt(99, 699))
        : 0;
    const amountTotal =
      listing.listingType === 'TASK'
        ? Number(listing.budgetAmount ?? quotedPrice)
        : 0;
    const platformFee = amountTotal > 0 ? Number((amountTotal * 0.06).toFixed(2)) : 0;
    const sellerIncome = Number((amountTotal - platformFee).toFixed(2));

    const application = await prisma.application.create({
      data: {
        id: `seed_order_application_${String(createdOrders + 1).padStart(3, '0')}`,
        listingId: listing.id,
        applicantId: applicant.id,
        message: `${city.label}附近可以接这单，我这周时间比较灵活，也方便线下碰面。`,
        quotedPrice,
        status: 'ACCEPTED',
        handledAt: createdAt,
        handledBy: 'seed-order-bot',
        createdAt,
        updatedAt: createdAt,
      },
    });

    const order = await prisma.order.create({
      data: {
        listingId: listing.id,
        applicationId: application.id,
        buyerId: listing.publisherId,
        sellerId: applicant.id,
        orderType: listing.listingType === 'TASK' ? 'TASK_ORDER' : 'EXCHANGE_CONFIRMATION',
        amountTotal,
        platformFee,
        sellerIncome,
        escrowStatus:
          amountTotal > 0
            ? selectedStatus === 'PENDING_PAYMENT'
              ? 'PENDING_PAYMENT'
              : selectedStatus === 'COMPLETED'
                ? 'RELEASED'
                : 'PAID'
            : 'NOT_REQUIRED',
        orderStatus: selectedStatus,
        scheduledAt: new Date(createdAt.getTime() + randomInt(1, 5) * 24 * 60 * 60 * 1000),
        deliveredAt:
          selectedStatus === 'PENDING_CONFIRMATION' || selectedStatus === 'COMPLETED'
            ? new Date(createdAt.getTime() + 2 * 24 * 60 * 60 * 1000)
            : null,
        completedAt:
          selectedStatus === 'COMPLETED'
            ? new Date(createdAt.getTime() + 3 * 24 * 60 * 60 * 1000)
            : null,
        createdAt,
        updatedAt: createdAt,
      },
    });

    await prisma.listing.update({
      where: { id: listing.id },
      data: {
        acceptedApplicationId: application.id,
        status:
          selectedStatus === 'COMPLETED'
            ? 'COMPLETED'
            : selectedStatus === 'PENDING_PAYMENT' || selectedStatus === 'PENDING_ACCEPT'
              ? 'MATCHED'
              : 'IN_PROGRESS',
        cityCode: listing.cityCode ?? city.code,
        longitude: listing.longitude ?? city.longitude,
        latitude: listing.latitude ?? city.latitude,
      },
    });

    const events = [
      ['CREATED', createdAt, listing.publisherId, 'buyer'],
    ];

    if (selectedStatus !== 'PENDING_PAYMENT' && amountTotal > 0) {
      const paidAt = new Date(createdAt.getTime() + 2 * 60 * 60 * 1000);
      events.push(['PAID', paidAt, listing.publisherId, 'buyer']);
      await prisma.payment.create({
        data: {
          orderId: order.id,
          payerId: listing.publisherId,
          paymentChannel: 'ALIPAY',
          amount: amountTotal,
          paymentStatus: 'PAID',
          paidAt,
          createdAt: paidAt,
          updatedAt: paidAt,
        },
      });
    }

    if (
      selectedStatus === 'IN_PROGRESS' ||
      selectedStatus === 'PENDING_CONFIRMATION' ||
      selectedStatus === 'COMPLETED'
    ) {
      events.push([
        'ACCEPTED',
        new Date(createdAt.getTime() + 5 * 60 * 60 * 1000),
        applicant.id,
        'seller',
      ]);
    }

    if (selectedStatus === 'PENDING_CONFIRMATION' || selectedStatus === 'COMPLETED') {
      events.push([
        'DELIVERED',
        new Date(createdAt.getTime() + 2 * 24 * 60 * 60 * 1000),
        applicant.id,
        'seller',
      ]);
    }

    if (selectedStatus === 'COMPLETED') {
      const confirmedAt = new Date(createdAt.getTime() + 3 * 24 * 60 * 60 * 1000);
      events.push(['CONFIRMED', confirmedAt, listing.publisherId, 'buyer']);

      await prisma.review.create({
        data: {
          orderId: order.id,
          fromUserId: listing.publisherId,
          toUserId: applicant.id,
          score: randomInt(4, 5),
          content: `${city.label}这次协作很顺，响应快，交付也比较稳定。`,
          status: 'VISIBLE',
          createdAt: confirmedAt,
          updatedAt: confirmedAt,
        },
      });
    }

    for (const [eventType, eventAt, operatorUserId, operatorRole] of events) {
      await prisma.orderEvent.create({
        data: {
          orderId: order.id,
          eventType,
          operatorUserId,
          operatorRole,
          createdAt: eventAt,
        },
      });
    }

    createdOrders += 1;
  }

  return createdOrders;
}

async function main() {
  const count = await resetOrderData();
  console.log(JSON.stringify({ ok: true, createdOrders: count }));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
