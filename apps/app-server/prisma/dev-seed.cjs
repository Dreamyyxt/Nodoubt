const { PrismaClient } = require('@prisma/client');
const { execFileSync } = require('node:child_process');

const prisma = new PrismaClient();

const amapRestKey =
  process.env.AMAP_REST_KEY || 'bcc50dd4de4be3576e5e40c1f2fce062';

const cityPool = [
  { code: 'beijing', label: '北京' },
  { code: 'shanghai', label: '上海' },
  { code: 'guangzhou', label: '广州' },
  { code: 'shenzhen', label: '深圳' },
  { code: 'hangzhou', label: '杭州' },
  { code: 'chengdu', label: '成都' },
  { code: 'wuhan', label: '武汉' },
  { code: 'nanjing', label: '南京' },
  { code: 'chongqing', label: '重庆' },
  { code: 'xiamen', label: '厦门' },
];

const realAddressPool = [
  {
    cityCode: 'beijing',
    cityLabel: '北京',
    venueName: '三里屯太古里',
    address: '北京市朝阳区三里屯路19号',
  },
  {
    cityCode: 'beijing',
    cityLabel: '北京',
    venueName: '798艺术区',
    address: '北京市朝阳区酒仙桥路4号',
  },
  {
    cityCode: 'beijing',
    cityLabel: '北京',
    venueName: '颐和园',
    address: '北京市海淀区新建宫门路19号',
  },
  {
    cityCode: 'beijing',
    cityLabel: '北京',
    venueName: '国家图书馆',
    address: '北京市海淀区中关村南大街33号',
  },
  {
    cityCode: 'beijing',
    cityLabel: '北京',
    venueName: '北京坊',
    address: '北京市西城区廊房头条21号',
  },
  {
    cityCode: 'shanghai',
    cityLabel: '上海',
    venueName: '外滩十八号',
    address: '上海市黄浦区中山东一路18号',
  },
  {
    cityCode: 'shanghai',
    cityLabel: '上海',
    venueName: '西岸美术馆',
    address: '上海市徐汇区龙腾大道2600号',
  },
  {
    cityCode: 'shanghai',
    cityLabel: '上海',
    venueName: '东方明珠',
    address: '上海市浦东新区世纪大道1号',
  },
  {
    cityCode: 'shanghai',
    cityLabel: '上海',
    venueName: '新天地',
    address: '上海市黄浦区马当路245号',
  },
  {
    cityCode: 'shanghai',
    cityLabel: '上海',
    venueName: '静安寺商圈',
    address: '上海市静安区南京西路1601号',
  },
  {
    cityCode: 'guangzhou',
    cityLabel: '广州',
    venueName: '太古汇',
    address: '广州市天河区天河路383号',
  },
  {
    cityCode: 'guangzhou',
    cityLabel: '广州',
    venueName: '广州塔',
    address: '广州市海珠区阅江西路222号',
  },
  {
    cityCode: 'guangzhou',
    cityLabel: '广州',
    venueName: '正佳广场',
    address: '广州市天河区天河路228号',
  },
  {
    cityCode: 'guangzhou',
    cityLabel: '广州',
    venueName: '永庆坊',
    address: '广州市荔湾区恩宁路99号',
  },
  {
    cityCode: 'guangzhou',
    cityLabel: '广州',
    venueName: '保利世贸博览馆',
    address: '广州市海珠区新港东路1000号',
  },
  {
    cityCode: 'shenzhen',
    cityLabel: '深圳',
    venueName: '万象天地',
    address: '深圳市南山区深南大道9668号',
  },
  {
    cityCode: 'shenzhen',
    cityLabel: '深圳',
    venueName: '平安金融中心',
    address: '深圳市福田区益田路5033号',
  },
  {
    cityCode: 'shenzhen',
    cityLabel: '深圳',
    venueName: '海上世界文化艺术中心',
    address: '深圳市南山区望海路1187号',
  },
  {
    cityCode: 'shenzhen',
    cityLabel: '深圳',
    venueName: '华侨城创意文化园',
    address: '深圳市南山区锦绣北街2号',
  },
  {
    cityCode: 'shenzhen',
    cityLabel: '深圳',
    venueName: '深圳湾万象城',
    address: '深圳市南山区科苑南路2888号',
  },
  {
    cityCode: 'hangzhou',
    cityLabel: '杭州',
    venueName: '湖滨银泰in77',
    address: '杭州市上城区延安路258号',
  },
  {
    cityCode: 'hangzhou',
    cityLabel: '杭州',
    venueName: '天目里',
    address: '杭州市西湖区天目山路398号',
  },
  {
    cityCode: 'hangzhou',
    cityLabel: '杭州',
    venueName: '杭州大厦',
    address: '杭州市拱墅区环城北路230号',
  },
  {
    cityCode: 'hangzhou',
    cityLabel: '杭州',
    venueName: '西溪湿地',
    address: '杭州市西湖区天目山路518号',
  },
  {
    cityCode: 'hangzhou',
    cityLabel: '杭州',
    venueName: '阿里巴巴西溪园区',
    address: '杭州市余杭区文一西路969号',
  },
  {
    cityCode: 'chengdu',
    cityLabel: '成都',
    venueName: '成都IFS',
    address: '成都市锦江区红星路三段1号',
  },
  {
    cityCode: 'chengdu',
    cityLabel: '成都',
    venueName: '成都远洋太古里',
    address: '成都市锦江区中纱帽街8号',
  },
  {
    cityCode: 'chengdu',
    cityLabel: '成都',
    venueName: '东郊记忆',
    address: '成都市成华区建设南支路4号',
  },
  {
    cityCode: 'chengdu',
    cityLabel: '成都',
    venueName: '宽窄巷子',
    address: '成都市青羊区宽巷子27号',
  },
  {
    cityCode: 'chengdu',
    cityLabel: '成都',
    venueName: '环球中心',
    address: '成都市武侯区天府大道北段1700号',
  },
  {
    cityCode: 'wuhan',
    cityLabel: '武汉',
    venueName: '武汉K11购物艺术中心',
    address: '武汉市硚口区解放大道387号',
  },
  {
    cityCode: 'wuhan',
    cityLabel: '武汉',
    venueName: '武汉天地',
    address: '武汉市江岸区卢沟桥路68号',
  },
  {
    cityCode: 'wuhan',
    cityLabel: '武汉',
    venueName: '湖北省博物馆',
    address: '武汉市武昌区东湖路160号',
  },
  {
    cityCode: 'wuhan',
    cityLabel: '武汉',
    venueName: '楚河汉街',
    address: '武汉市武昌区中北路171号',
  },
  {
    cityCode: 'wuhan',
    cityLabel: '武汉',
    venueName: '光谷步行街',
    address: '武汉市洪山区珞喻路726号',
  },
  {
    cityCode: 'nanjing',
    cityLabel: '南京',
    venueName: '德基广场',
    address: '南京市玄武区中山路18号',
  },
  {
    cityCode: 'nanjing',
    cityLabel: '南京',
    venueName: '南京博物院',
    address: '南京市玄武区中山东路321号',
  },
  {
    cityCode: 'nanjing',
    cityLabel: '南京',
    venueName: '老门东',
    address: '南京市秦淮区剪子巷54号',
  },
  {
    cityCode: 'nanjing',
    cityLabel: '南京',
    venueName: '先锋书店五台山店',
    address: '南京市鼓楼区广州路173号',
  },
  {
    cityCode: 'nanjing',
    cityLabel: '南京',
    venueName: '1912街区',
    address: '南京市玄武区长江后街8号',
  },
  {
    cityCode: 'chongqing',
    cityLabel: '重庆',
    venueName: '重庆来福士',
    address: '重庆市渝中区接圣街8号',
  },
  {
    cityCode: 'chongqing',
    cityLabel: '重庆',
    venueName: '观音桥步行街',
    address: '重庆市江北区建新西路2号',
  },
  {
    cityCode: 'chongqing',
    cityLabel: '重庆',
    venueName: '龙门浩老街',
    address: '重庆市南岸区南滨路105号',
  },
  {
    cityCode: 'chongqing',
    cityLabel: '重庆',
    venueName: '李子坝观景平台',
    address: '重庆市渝中区李子坝正街39号',
  },
  {
    cityCode: 'chongqing',
    cityLabel: '重庆',
    venueName: '解放碑步行街',
    address: '重庆市渝中区民权路89号',
  },
  {
    cityCode: 'xiamen',
    cityLabel: '厦门',
    venueName: '厦门大学',
    address: '厦门市思明区演武西路181号',
  },
  {
    cityCode: 'xiamen',
    cityLabel: '厦门',
    venueName: '沙坡尾艺术西区',
    address: '厦门市思明区大学路沙坡尾60号',
  },
  {
    cityCode: 'xiamen',
    cityLabel: '厦门',
    venueName: 'SM城市广场',
    address: '厦门市湖里区嘉禾路468号',
  },
  {
    cityCode: 'xiamen',
    cityLabel: '厦门',
    venueName: '中山路步行街',
    address: '厦门市思明区中山路56号',
  },
  {
    cityCode: 'xiamen',
    cityLabel: '厦门',
    venueName: '厦门园林植物园',
    address: '厦门市思明区思明南路422号',
  },
];

const taskTemplates = [
  {
    title: '陪我去看这个周末展览并顺手拍几张有氛围的照片',
    description:
      '想认真去看一个展，但一个人去总差点意思。希望你愿意一起逛、一起聊，顺手帮我留下几张自然的纪念照。',
    serviceMode: 'OFFLINE',
    budgetRange: [88, 268],
  },
  {
    title: '陪我吃一顿治愈系晚饭，听我把最近的糟心事讲完',
    description:
      '不需要你提供解决方案，只希望你是一个愿意认真听人讲话、情绪稳定又不尴尬的人。饭我请，也会付你时间费。',
    serviceMode: 'OFFLINE',
    budgetRange: [99, 199],
  },
  {
    title: '替我去一个城市角落打卡并帮我带回十张有故事感的照片',
    description:
      '我最近在做一个“城市小角落”相册计划，想收集那些不那么热门、但看起来有情绪的地方。希望你会观察、会讲述。',
    serviceMode: 'OFFLINE',
    budgetRange: [120, 360],
  },
  {
    title: '帮我替一个迟迟说不出口的人，送一束花并带一句体面的话',
    description:
      '不是恶作剧，也不是情感纠纷。只是想找一个表达清楚、态度温和的人，帮我把一段关系认真收个尾。',
    serviceMode: 'OFFLINE',
    budgetRange: [150, 320],
  },
  {
    title: '帮我陪家里长辈去一次医院或办事窗口，负责耐心解释和流程陪同',
    description:
      '事情本身不复杂，但老人家一个人会紧张。希望你稳一点、细心一点，愿意把流程讲明白。',
    serviceMode: 'OFFLINE',
    budgetRange: [120, 280],
  },
  {
    title: '帮我把一场很普通的生日过得稍微像电影一点',
    description:
      '不需要你策划大场面，只希望你能帮我一起想一个小小流程、布置一点氛围，再在关键时刻留下几张会让我以后翻出来还会笑的照片。',
    serviceMode: 'OFFLINE',
    budgetRange: [168, 420],
  },
  {
    title: '陪我完成一个一直想做但一个人迟迟没开始的小计划',
    description:
      '可能是晨跑、学轮滑、第一次逛菜市场、第一次去跳蚤市场摆摊。想找一个愿意认真陪我开始的人。',
    serviceMode: 'OFFLINE',
    budgetRange: [88, 240],
  },
  {
    title: '帮我把租来的房间改得更像“我在这里生活”，而不是临时住一下',
    description:
      '不需要你是专业设计师，但希望你审美在线，能陪我逛一圈，帮我挑几个便宜但不敷衍的小东西。',
    serviceMode: 'OFFLINE',
    budgetRange: [150, 380],
  },
  {
    title: '替我记录一场小活动，重点拍人与人之间的感觉，不只是流程',
    description:
      '活动不大，但我想留下的是大家真的在互动、真的开心、真的有点被打动的瞬间。',
    serviceMode: 'OFFLINE',
    budgetRange: [220, 520],
  },
  {
    title: '帮我临时照看半天猫咪，顺便陪它认真玩一会儿',
    description:
      '不是单纯喂粮换水，更希望你愿意陪它玩、观察状态，再给我发几张像在写小日记一样的照片。',
    serviceMode: 'OFFLINE',
    budgetRange: [80, 220],
  },
];

const exchangeTemplates = [
  {
    title: '给你拍一组生活感照片，换你帮我把简历改得更像我',
    description:
      '我会拍比较自然的照片，也能做基础修图。希望你不是模板式修改，而是真的帮我梳理一下表达方式。',
    offer: '生活感拍摄、基础修图',
    want: '简历优化、表达梳理',
    serviceMode: 'BOTH',
  },
  {
    title: '我帮你剪一条有节奏的短视频，换你陪我练几次英语口语',
    description:
      '我偏会做 vlog 和探店风格的节奏剪辑，希望你发音自然、愿意真的陪我张口，不只是照本宣科。',
    offer: '短视频剪辑、字幕节奏',
    want: '英语口语陪练',
    serviceMode: 'ONLINE',
  },
  {
    title: '我帮你做活动海报，换你帮我把探店文字写得更有画面感',
    description:
      '我能做一张不难看的海报和基础排版，希望你擅长写“看起来像真有人在经历”的文案，而不是流水账。',
    offer: '活动海报、基础排版',
    want: '探店文案、文字润色',
    serviceMode: 'ONLINE',
  },
  {
    title: '我陪你开始健身，换你帮我拍一组不用太端着的人像',
    description:
      '我可以陪你做入门训练和动作纠正，希望你会拍“像朋友眼里的我”那种照片，而不是影楼感。',
    offer: '入门健身陪练、动作纠正',
    want: '自然人像、照片筛选',
    serviceMode: 'OFFLINE',
  },
  {
    title: '我帮你把 PPT 做顺眼，换你来帮我跟拍一次线下小活动',
    description:
      '我可以把现有 PPT 调整得更清爽有秩序，希望你愿意帮我记录一次线下活动，不用花哨，但要有现场感。',
    offer: 'PPT 美化、排版优化',
    want: '活动跟拍、现场记录',
    serviceMode: 'BOTH',
  },
  {
    title: '我教你做基础手冲咖啡，换你带我第一次逛跳蚤市场',
    description:
      '我可以把手冲入门步骤和器具逻辑讲清楚，希望你愿意带我去一个有意思的周末市集，让我别一个人社恐。',
    offer: '手冲咖啡入门、器具建议',
    want: '跳蚤市场带逛、周末陪伴',
    serviceMode: 'OFFLINE',
  },
  {
    title: '我帮你修一套旅行照片，换你陪我练一次公开表达',
    description:
      '我会做基础修图和统一色调，希望你愿意听我讲一段准备已久但总不敢开口的分享，并给我反馈。',
    offer: '旅行照片修图、色调统一',
    want: '公开表达陪练、反馈建议',
    serviceMode: 'BOTH',
  },
];

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(list) {
  return list[randomInt(0, list.length - 1)];
}

function randomRecentDate() {
  const now = Date.now();
  const daysBack = randomInt(0, 14);
  const hoursBack = randomInt(0, 23);
  return new Date(now - (daysBack * 24 + hoursBack) * 60 * 60 * 1000);
}

async function geocodeAddress(address, cityLabel) {
  const url = new URL('https://restapi.amap.com/v3/geocode/geo');
  url.searchParams.set('key', amapRestKey);
  url.searchParams.set('address', address);
  url.searchParams.set('city', cityLabel);

  const responseText = execFileSync('curl', ['-s', url.toString()], {
    encoding: 'utf8',
    maxBuffer: 1024 * 1024,
  });
  const payload = JSON.parse(responseText);

  if (
    payload.status !== '1' ||
    !Array.isArray(payload.geocodes) ||
    payload.geocodes.length === 0
  ) {
    throw new Error(`Failed to geocode ${address}: ${JSON.stringify(payload)}`);
  }

  const first = payload.geocodes[0];
  const [longitude, latitude] = String(first.location)
    .split(',')
    .map((item) => Number(item));

  if (!Number.isFinite(longitude) || !Number.isFinite(latitude)) {
    throw new Error(`Invalid geocode result for ${address}: ${JSON.stringify(first)}`);
  }

  return {
    formattedAddress: first.formatted_address || address,
    longitude,
    latitude,
  };
}

async function upsertUser(id, phone, nickname, cityCode) {
  const existingByPhone = await prisma.user.findUnique({
    where: { phone },
    select: { id: true },
  });

  if (existingByPhone) {
    return prisma.user.update({
      where: { id: existingByPhone.id },
      data: {
        nickname,
        cityCode,
      },
    });
  }

  return prisma.user.upsert({
    where: { id },
    update: {
      phone,
      nickname,
      cityCode,
    },
    create: {
      id,
      phone,
      nickname,
      cityCode,
    },
  });
}

async function wipeListingGraph() {
  await prisma.review.deleteMany({});
  await prisma.refund.deleteMany({});
  await prisma.payment.deleteMany({});
  await prisma.orderEvent.deleteMany({});
  await prisma.favorite.deleteMany({});
  await prisma.chatMember.deleteMany({});
  await prisma.message.deleteMany({});
  await prisma.chat.deleteMany({});
  await prisma.order.deleteMany({});
  await prisma.application.deleteMany({});
  await prisma.listingImage.deleteMany({});
  await prisma.report.deleteMany({
    where: { targetType: 'LISTING' },
  });
  await prisma.listing.deleteMany({});
}

async function seedUsers() {
  const users = [];

  for (let index = 0; index < 18; index += 1) {
    const city = cityPool[index % cityPool.length];
    const user = await upsertUser(
      `seed_user_${String(index + 1).padStart(3, '0')}`,
      `1881000${String(index + 1).padStart(4, '0')}`,
      `${city.label}任务发起人${index + 1}`,
      city.code,
    );
    users.push(user);
  }

  await upsertUser(
    'demo_publisher_001',
    '13900000001',
    '同城靠谱发布者',
    'shanghai',
  );
  await upsertUser(
    'demo_helper_001',
    '13800000000',
    '默认用户',
    'shanghai',
  );
  await upsertUser(
    'dev_user_001',
    '13800000001',
    '发布者',
    'beijing',
  );

  return users;
}

async function createListing(id, publisherId, data) {
  return prisma.listing.create({
    data: {
      id,
      publisherId,
      ...data,
    },
  });
}

async function main() {
  await wipeListingGraph();
  const users = await seedUsers();

  let createdCount = 0;

  for (let index = 0; index < realAddressPool.length; index += 1) {
    const spot = realAddressPool[index];
    const publisher = users[index % users.length];
    const createdAt = randomRecentDate();
    const isTask = index % 2 === 0;
    const geocoded = await geocodeAddress(spot.address, spot.cityLabel);

    if (isTask) {
      const template = pick(taskTemplates);
      const budget = randomInt(template.budgetRange[0], template.budgetRange[1]);
      const shouldFeature =
        budget >= 420 || (budget >= 320 && index % 8 === 0);
      const featuredPriority =
        budget >= 480 ? 5 : budget >= 380 ? 4 : shouldFeature ? 3 : 0;
      await createListing(`seed_listing_${String(index + 1).padStart(3, '0')}`, publisher.id, {
        listingType: 'TASK',
        title: `${spot.venueName}${template.title}`,
        description: `${template.description} 集合地点在${spot.venueName}，地址是${geocoded.formattedAddress}，希望这周能约上。`,
        cityCode: spot.cityCode,
        locationText: geocoded.formattedAddress,
        longitude: geocoded.longitude,
        latitude: geocoded.latitude,
        serviceMode: template.serviceMode,
        budgetType: Math.random() > 0.35 ? 'FIXED' : 'NEGOTIABLE',
        budgetAmount: budget,
        visibility: 'PUBLIC',
        status: 'PUBLISHED',
        auditStatus: 'APPROVED',
        isUrgent: Math.random() > 0.74,
        isFeatured: shouldFeature,
        featuredPriority,
        featuredAt: shouldFeature ? createdAt : null,
        featuredUntil: shouldFeature
          ? new Date(createdAt.getTime() + 7 * 24 * 60 * 60 * 1000)
          : null,
        opsNote: shouldFeature
          ? `运营判断：${spot.venueName} 场景明确，任务自带故事感，适合优先推动成交。`
          : null,
        publishedAt: createdAt,
        createdAt,
      });
    } else {
      const template = pick(exchangeTemplates);
      await createListing(`seed_listing_${String(index + 1).padStart(3, '0')}`, publisher.id, {
        listingType: 'EXCHANGE',
        title: `${spot.venueName}${template.title}`,
        description: `${template.description} 见面地点可以约在${spot.venueName}，地址是${geocoded.formattedAddress}，如果投缘可以长期互换。`,
        cityCode: spot.cityCode,
        locationText: geocoded.formattedAddress,
        longitude: geocoded.longitude,
        latitude: geocoded.latitude,
        serviceMode: template.serviceMode,
        budgetType: 'FREE_EXCHANGE',
        exchangeOfferText: template.offer,
        exchangeWantText: template.want,
        visibility: 'PUBLIC',
        status: 'PUBLISHED',
        auditStatus: 'APPROVED',
        isUrgent: Math.random() > 0.82,
        publishedAt: createdAt,
        createdAt,
      });
    }

    createdCount += 1;
  }

  console.log(
    JSON.stringify(
      {
        ok: true,
        createdListings: createdCount,
        cities: [...new Set(realAddressPool.map((item) => item.cityLabel))].length,
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
