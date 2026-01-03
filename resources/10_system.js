/**
 * =========================================================================
 * Description : Custom System Information Page for LuCI (10_system.js)
 * License     : MIT
 * Author      : Reyanmatic
 * Website     : https://www.reyanmatic.com
 * Date        : 2026-01-03
 * Version     : 1.2.0
 * Update/Fixed: Optimized banner CSS styles;
 *               Fixed scrolling animation smoothness;
 *               Added standard file header for version tracking.
 *               Placeholder {BUILD_DATE} will be replaced by diy-part2.sh.
 * =========================================================================
 */

'use strict';
'require baseclass';
'require fs';
'require rpc';

// RPC方法声明
var callLuciVersion = rpc.declare({ object: 'luci', method: 'getVersion' });
var callSystemBoard = rpc.declare({ object: 'system', method: 'board' });
var callSystemInfo = rpc.declare({ object: 'system', method: 'info' });
var callCPUBench    = rpc.declare({ object: 'luci', method: 'getCPUBench' });
var callCPUInfo     = rpc.declare({ object: 'luci', method: 'getCPUInfo' });
var callCPUUsage    = rpc.declare({ object: 'luci', method: 'getCPUUsage' });
var callTempInfo    = rpc.declare({ object: 'luci', method: 'getTempInfo' });

/**
 * 确保Banner和样式只插入一次
 * 去除光影效果，字体更大
 */
function ensureScrollerBannerAndStyle() {
    if (!document.getElementById('scroller-banner-style')) {
        var style = document.createElement('style');
        style.id = 'scroller-banner-style';
        style.type = 'text/css';
        style.innerHTML =
            // 整体Banner容器
            '.banner-container{width:100%;max-width:1200px;margin:0 auto 16px auto;padding:6px;box-sizing:border-box;position:relative;overflow:hidden;}' + // margin:0 auto 16px auto; -> 顶部、左右居中，底部留16px
            // 表格撑满banner
            '.banner-table{width:100%;border-collapse:separate;border-spacing:0;table-layout:fixed;position:relative;height:36px;}' + // height:36px; -> 条的高度
            // 行容器
            '.shine-wrapper{position:relative;overflow:hidden;display:table-row;}' +

            // 左侧蓝色条（含®）
            '#fixedCell{' +
                'font-family:Roboto,Arial,sans-serif;' +
                'font-size:clamp(16px,2.5vw,22px);' +     /* 字体自适应，最小16px，最大22px */
                'font-weight:bold;' +
                'background-color:#0860A5;' +
                'color:white;' +
                'width:33%;' +                           /* 蓝色条占60%宽度 */
                'padding:12px 24px 4px 8px;' +           /* 上12px，右24px，下4px，左8px */
                'white-space:nowrap;' +
                'overflow:hidden;' +
                'text-overflow:ellipsis;' +
                'border-radius:4px 0 0 4px;' +           /* 左侧圆角 */
                'position:relative;' +
            '}' +

            // “®”标识
            '#fixedCell::after{' +
                'content:"®";' +
                'font-size:0.6em;' +
                'position:relative;' +
                'top:-1.1em;' +                          /* 向上偏移“®”到右上角 */
                'margin-left:-0.5px;' +
                'font-weight:normal;' +
            '}' +

            // 右侧橙色条（动画宽度变化）
            '#movingCell{' +
                'font-family:Roboto,Arial,sans-serif;' +
                'font-size:clamp(16px,2.5vw,22px);' +   /* 字体自适应，最小16px，最大22px */
                'font-weight:bold;' +
                'background-color:#E78405;' +
                'color:white;' +
                'text-align:center;' +
                'width:67%;' +                          /* 默认橙色条宽度40% */
                'padding:8px;' +                        /* 上下左右各8px，控制上下和左右间距 */
                'white-space:nowrap;' +
                'overflow:hidden;' +
                'animation:mymove 3s infinite;' +       /* 宽度动画，3秒循环 */
                'border-radius:0 4px 4px 0;' +          /* 右侧圆角 */
                'position:relative;' +
            '}' +

            // 鼠标悬停浮起效果
            '#fixedCell:hover,#movingCell:hover{' +
                'transform:translateZ(10px);' +
                'transition:transform 0.3s ease;' +
            '}' +

            // 橙色bar宽度动画，实际是“width”属性变化，动画区间如下↓
            '@keyframes mymove{' +
                '0%{width:67%;}' +                      /* 起始宽度40%，右边缘与初始位置对齐 */
                '50%{width:33%;}' +                     /* 最大宽度70%，右边缘依然对齐，左边扩展 */
                '100%{width:67%;}' +                    /* 回到初始宽度40% */
            '}' +

            // 小屏幕自适应，条高度、宽度、圆角等参数
            '@media screen and (max-width:575.98px){' +
                '.banner-table{min-width:280px;height:32px;}' +
                '#fixedCell{width:50%;}' +              /* 蓝色条宽度缩为55% */
                '#movingCell{width:50%;}' +             /* 橙色条宽度缩为45% */
                '@keyframes mymove{0%{width:50%;}50%{width:50%;}100%{width:50%;}}' + /* 移动区间与宽度同步缩放 mymove{0%{width:45%;}50%{width:65%;}100%{width:45%;} */
            '}' +

            // 平板等中等屏幕宽度适配
            '@media screen and (min-width:576px) and (max-width:767.98px){' +
                '#fixedCell{width:45%;}' +   /* 58% */
                '#movingCell{width:55%;}' +  /* 42% */
                '@keyframes mymove{0%{width:45%;}50%{width:55%;}100%{width:45%;}}' +  /* mymove{0%{width:42%;}50%{width:68%;}100%{width:42%;}} */
            '}' +

            // 其它大屏幕宽度适配
            '@media screen and (min-width:768px) and (max-width:991.98px){' +
                '#fixedCell{width:33%;}' +  /* 60% */
                '#movingCell{width:67%;}' + /* 40% */
            '}' +
            '@media screen and (min-width:992px){' +
                '#fixedCell{width:33%;}' +  /* 60% */
                '#movingCell{width:67%;}' + /* 40% */
            '}';
        document.head.appendChild(style);
    }

    // 插入Banner
    if (!document.getElementById('scroller-banner')) {
        var banner = document.createElement('div');
        banner.className = 'banner-container';
        banner.id = 'scroller-banner';
        banner.innerHTML =
            '<table class="banner-table">' +
                '<tr class="shine-wrapper">' +
                    '<td id="fixedCell">苏州睿研自动化科技</td>' +
                    '<td id="movingCell">您的自动化解决方案专家!</td>' +
                '</tr>' +
            '</table>';
        // 兼容不同主题的内容区选择
        var main = document.querySelector('section.main') || document.getElementById('maincontent') || document.getElementById('content') || document.body;
        if (main && !main.querySelector('#scroller-banner')) {
            main.insertBefore(banner, main.firstChild);
        }
    }
}

return baseclass.extend({
    title: _('System'),

    // 加载系统信息
    load: function() {
        return Promise.all([
            L.resolveDefault(callSystemBoard(), {}),
            L.resolveDefault(callSystemInfo(), {}),
            L.resolveDefault(callCPUBench(), {}),
            L.resolveDefault(callCPUInfo(), {}),
            L.resolveDefault(callCPUUsage(), {}),
            L.resolveDefault(callTempInfo(), {}),
            L.resolveDefault(callLuciVersion(), { revision: _('unknown version'), branch: 'LuCI' })
        ]);
    },

    // 渲染系统信息表格
    render: function(data) {
        // 确保Banner和样式在内容区顶部
        setTimeout(ensureScrollerBannerAndStyle, 10);

        var boardinfo   = data[0],
            systeminfo  = data[1],
            cpubench    = data[2],
            cpuinfo     = data[3],
            cpuusage    = data[4],
            tempinfo    = data[5],
            luciversion = data[6];

        luciversion = luciversion.branch + ' ' + luciversion.revision;

        // 格式化本地时间
        var datestr = null;
        if (systeminfo.localtime) {
            var date = new Date(systeminfo.localtime * 1000);
            datestr = '%04d-%02d-%02d %02d:%02d:%02d'.format(
                date.getUTCFullYear(),
                date.getUTCMonth() + 1,
                date.getUTCDate(),
                date.getUTCHours(),
                date.getUTCMinutes(),
                date.getUTCSeconds()
            );
        }

        // 信息字段
        var fields = [
            _('Hostname'),         boardinfo.hostname,
            _('Model'),            boardinfo.model + cpubench.cpubench,
            _('Architecture'),     cpuinfo.cpuinfo || boardinfo.system,
            _('Target Platform'),  (L.isObject(boardinfo.release) ? boardinfo.release.target : ''),
            _('Firmware Version'), '睿研 定制版 Ver.{BUILD_DATE} / ' + (luciversion || ''),
            _('Kernel Version'),   boardinfo.kernel,
            _('Local Time'),       datestr,
            _('Uptime'),           systeminfo.uptime ? '%t'.format(systeminfo.uptime) : null,
            _('Load Average'),     Array.isArray(systeminfo.load) ? '%.2f, %.2f, %.2f'.format(
                systeminfo.load[0] / 65535.0,
                systeminfo.load[1] / 65535.0,
                systeminfo.load[2] / 65535.0
            ) : null,
            _('CPU Usage (%)'),    cpuusage.cpuusage
        ];

        // 如有温度信息则插入
        if (tempinfo.tempinfo) {
            fields.splice(6, 0, _('Temperature'));
            fields.splice(7, 0, tempinfo.tempinfo);
        }

        // 构建表格
        var table = E('table', { 'class': 'table' });
        for (var i = 0; i < fields.length; i += 2) {
            table.appendChild(E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left', 'width': '33%' }, [ fields[i] ]),
                E('td', { 'class': 'td left' }, [ (fields[i + 1] != null) ? fields[i + 1] : '?' ])
            ]));
        }

        // 返回内容（Banner已独立插入，避免重复刷新）
        return E('div', {}, [
            table
        ]);
    }
});
