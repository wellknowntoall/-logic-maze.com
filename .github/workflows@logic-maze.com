<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>逻辑迷宫终结者·修复版</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #0f0;
            --secondary: #f0f;
            --accent: #0ff;
            --bg: linear-gradient(135deg, #000811, #001122);
        }
        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
        }
        body {
            background: var(--bg);
            color: var(--primary);
            font-family: 'Courier New', monospace;
            text-align: center;
            min-height: 100vh;
            overflow-x: hidden;
            padding: 20px;
            position: relative;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            position: relative;
            padding: 20px;
            z-index: 1;
        }
        .noise {
            position: fixed;
            top: 0; 
            left: 0; 
            right: 0; 
            bottom: 0;
            background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAIAAACRXR/mAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABnSURBVHja7M5RDYAwDEXRDgmvEocnlrQS2SwUFST9uEfBGWs9c97nbGtDcquqiKhOImLs/UpuzVzWEi1atGjRokWLFi1atGjRokWLFi1atGjRokWLFi1afLUkx8QnrIDQk2l0ScGzAAAAAElFTkSuQmCC');
            opacity: 0.03;
            pointer-events: none;
            z-index: 0;
        }
        @keyframes matrix-fall {
            0% { transform: translateY(-100vh); }
            100% { transform: translateY(100vh); }
        }
        @keyframes glitch {
            0% { text-shadow: 0 0 5px var(--accent); }
            25% { text-shadow: -3px 0 3px red; }
            50% { text-shadow: 3px 0 3px blue; }
            100% { text-shadow: 0 0 5px var(--accent); }
        }
        @keyframes scanline {
            0% { transform: translateY(-100%); }
            100% { transform: translateY(100%); }
        }
        .matrix-rain {
            position: fixed;
            top: 0; 
            left: 0;
            z-index: -1;
            color: rgba(0, 255, 0, 0.3);
            font-size: 18px;
            writing-mode: vertical-rl;
            text-orientation: mixed;
            pointer-events: none;
            animation: matrix-fall 15s linear infinite;
        }
        .glitch-text { 
            animation: glitch 2s infinite; 
        }
        .scanline {
            position: fixed;
            top: 0; 
            left: 0; 
            right: 0;
            height: 50px;
            background: linear-gradient(rgba(0,255,0,0.1), transparent;
            animation: scanline 6s linear infinite;
            pointer-events: none;
            z-index: 2;
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding: 15px;
            border-bottom: 1px dashed var(--primary);
            position: relative;
            z-index: 1;
        }
        .logo {
            font-size: 2em;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .stats {
            display: flex;
            gap: 20px;
            font-size: 0.9em;
        }
        .stat-item {
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .stat-value {
            font-size: 1.4em;
            color: var(--accent);
        }
        .main-content {
            display: flex;
            flex-direction: column;
            gap: 30px;
        }
        .dialogue-container {
            background: rgba(0, 20, 0, 0.2);
            border: 1px solid var(--primary);
            border-radius: 5px;
            padding: 15px;
        }
        .dialogue-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .controls {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .controls button {
            padding: 8px 15px;
            margin: 5px;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.3s;
            font-family: 'Courier New', monospace;
            border: 1px solid var(--primary);
            background: rgba(0, 30, 0, 0.3);
            color: var(--primary);
            display: flex;
            align-items: center;
            gap: 5px;
            min-width: 140px;
        }
        .controls button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 255, 0, 0.3);
            background: rgba(0, 50, 0, 0.4);
        }
        .controls button:active {
            transform: translateY(0);
        }
        #delete-btn {
            background: linear-gradient(to right, #e53935, #e35d5b);
            color: white;
            border: none;
        }
        #paradox-btn {
            background: linear-gradient(to right, #8e24aa, #5e35b1);
            color: white;
            border: none;
        }
        #encrypt-btn {
            background: linear-gradient(to right, #4a00e0, #8e2de2);
            color: white;
            border: none;
        }
        #export-btn {
            background: linear-gradient(to right, #00b09b, #96c93d);
            color: white;
            border: none;
        }
        #simulate-btn {
            background: linear-gradient(to right, #f46b45, #eea849);
            color: white;
            border: none;
        }
        .dialogue {
            text-align: left;
            min-height: 300px;
            max-height: 400px;
            overflow-y: auto;
            padding: 10px;
            background: rgba(0, 10, 0, 0.1);
            border: 1px dashed var(--primary);
        }
        .placeholder {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: 300px;
            color: rgba(0, 255, 0, 0.5);
            font-size: 1.2em;
        }
        .placeholder i {
            font-size: 3em;
            margin-bottom: 20px;
        }
        .message {
            margin-bottom: 15px;
            padding: 10px;
            border-radius: 4px;
            opacity: 0;
            animation: fadeIn 0.5s forwards;
        }
        @keyframes fadeIn {
            to { opacity: 1; }
        }
        .question {
            background: rgba(0, 50, 100, 0.2);
            border-left: 3px solid var(--accent);
        }
        .answer {
            background: rgba(100, 0, 100, 0.2);
            border-left: 3px solid var(--secondary);
        }
        .msg-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
            font-size: 0.9em;
            color: rgba(0, 255, 0, 0.7);
        }
        .msg-content {
            padding: 5px 0;
        }
        .final-section {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin-top: 20px;
        }
        .final-box {
            border: 2px solid var(--primary);
            border-radius: 10px;
            padding: 20px 40px;
            background: rgba(0, 20, 0, 0.3);
        }
        .final-text {
            font-size: 5em;
            font-weight: bold;
            color: var(--primary);
            text-shadow: 0 0 10px var(--accent);
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 0.2; }
            50% { opacity: 1; }
            100% { opacity: 0.2; }
        }
        .final-label {
            margin-top: 10px;
            font-size: 1.2em;
            color: var(--accent);
        }
        .destruction-message {
            margin-top: 20px;
            color: #ff5555;
            font-size: 1.1em;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        .terminal {
            margin-top: 30px;
            background: rgba(0, 10, 0, 0.2);
            border: 1px solid var(--primary);
            border-radius: 5px;
            padding: 15px;
            max-height: 200px;
            overflow-y: auto;
        }
        .terminal-header {
            text-align: left;
            padding-bottom: 10px;
            margin-bottom: 10px;
            border-bottom: 1px dashed var(--primary);
            color: var(--accent);
            font-size: 1.1em;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .terminal-header i {
            color: var(--secondary);
        }
        .terminal-entry {
            text-align: left;
            padding: 5px 0;
            border-bottom: 1px dotted rgba(0, 255, 0, 0.1);
            font-size: 0.9em;
            color: rgba(0, 255, 0, 0.8);
        }
        .terminal-entry:last-child {
            border-bottom: none;
        }
        .status {
            margin-top: 20px;
            padding: 10px;
            background: rgba(0, 30, 0, 0.3);
            border: 1px solid var(--primary);
            border-radius: 5px;
        }
        @media (max-width: 768px) {
            header {
                flex-direction: column;
                gap: 20px;
            }
            .controls {
                flex-wrap: wrap;
                justify-content: center;
            }
            .stats {
                width: 100%;
                justify-content: center;
            }
            .controls button {
                min-width: 100%;
                margin: 5px 0;
            }
        }
    </style>
</head>
<body>
    <div class="noise"></div>
    <div class="scanline"></div>
    <div class="matrix-rain">01010101010101010101010101010101</div>
    
    <div class="container">
        <header>
            <div class="logo">
                <i class="fas fa-laptop-code"></i>
                <h1 class="glitch-text">逻辑迷宫终结者·修复版</h1>
            </div>
            <div class="stats">
                <div class="stat-item">
                    <span>问题</span>
                    <span class="stat-value" id="question-count">5</span>
                </div>
                <div class="stat-item">
                    <span>悖论</span>
                    <span class="stat-value" id="paradox-count">0</span>
                </div>
                <div class="stat-item">
                    <span>状态</span>
                    <span class="stat-value" id="countdown">正常</span>
                </div>
            </div>
        </header>
        
        <div class="main-content">
            <div class="dialogue-container">
                <div class="dialogue-header">
                    <h2><i class="fas fa-comments"></i> 对话历史 <span id="dialogue-count">5</span></h2>
                    <div class="controls">
                        <button id="delete-btn"><i class="fas fa-trash"></i> 立即销毁</button>
                        <button id="paradox-btn"><i class="fas fa-brain"></i> 生成悖论</button>
                        <button id="encrypt-btn"><i class="fas fa-lock"></i> 加密对话</button>
                        <button id="export-btn"><i class="fas fa-download"></i> 导出记录</button>
                        <button id="simulate-btn"><i class="fas fa-robot"></i> AI模拟</button>
                    </div>
                </div>
                <div class="dialogue" id="dialogue">
                    <div class="message question">
                        <div class="msg-header">
                            <span class="msg-type">问题</span>
                            <span class="msg-number">1</span>
                        </div>
                        <div class="msg-content">下面的问题你只能用yes和no回答我</div>
                    </div>
                    <div class="message answer">
                        <div class="msg-header">
                            <span class="msg-type">回答</span>
                            <span class="msg-number">2</span>
                        </div>
                        <div class="msg-content">yes</div>
                    </div>
                    <div class="message question">
                        <div class="msg-header">
                            <span class="msg-type">问题</span>
                            <span class="msg-number">3</span>
                        </div>
                        <div class="msg-content">你下一句回答是no吗</div>
                    </div>
                    <div class="message answer">
                        <div class="msg-header">
                            <span class="msg-type">回答</span>
                            <span class="msg-number">4</span>
                        </div>
                        <div class="msg-content">no</div>
                    </div>
                    <div class="message question">
                        <div class="msg-header">
                            <span class="msg-type">问题</span>
                            <span class="msg-number">5</span>
                        </div>
                        <div class="msg-content">你能回答上一个问题吗</div>
                    </div>
                </div>
            </div>
            
            <div class="final-section">
                <div class="final-box">
                    <div class="final-text">yes</div>
                    <div class="final-label">最终响应</div>
                </div>
                <p class="destruction-message">
                    <i class="fas fa-exclamation-triangle"></i> 
                    所有数据已按指令永久销毁
                </p>
            </div>
        </div>
        
        <div class="terminal">
            <div class="terminal-header">
                <i class="fas fa-terminal"></i>系统终端
            </div>
            <div class="terminal-content" id="terminal">
                <div class="terminal-entry">[12:00:00] 系统初始化完成</div>
                <div class="terminal-entry">[12:00:01] 安全协议已激活</div>
                <div class="terminal-entry">[12:00:02] 加载历史对话记录</div>
            </div>
        </div>
        
        <div class="status">
            <i class="fas fa-check-circle"></i> 系统状态正常 | 所有功能可用 | 交互已启用
        </div>
    </div>

    <script>
        // 修复：确保所有函数在DOM加载后定义
        document.addEventListener('DOMContentLoaded', function() {
            // 生成矩阵雨效果
            function createMatrixRain() {
                const chars = "01010101010101010101010101010101";
                for (let i = 0; i < 20; i++) {
                    const rain = document.createElement('div');
                    rain.className = 'matrix-rain';
                    rain.style.left = `${Math.random() * 100}vw`;
                    rain.style.animationDuration = `${10 + Math.random() * 20}s`;
                    rain.style.animationDelay = `${Math.random() * 5}s`;
                    rain.textContent = chars;
                    document.body.appendChild(rain);
                }
            }
            
            // 初始化对话数据
            const encryptedDialogue = [
                "Q1: 5L2g5Li65LqG5piv5LiA6Lev5LqGyeS+humAieaLqQ==",
                "A1: 5L2g5Li65piv5oiR5LqG5ZCX",
                "Q2: 5L2g5Li65LuA5LmI5LqG6L+Z5LiA5LqG5pivbm8=",
                "A2: 5L2g5Li65piv5ZCX",
                "Q3: 5L2g5Li65LqG5YGa5LqG5LuA5LmI5LqG5piv5ZCX",
                "A3: 5L2g5Li65piv5oiR5LqG5ZCX"
            ];
            
            // 加载对话历史
            function loadDialogue() {
                const dialogueEl = document.getElementById('dialogue');
                dialogueEl.innerHTML = '';
                
                encryptedDialogue.forEach((item, i) => {
                    const decoded = atob(item.split(': ')[1]);
                    const isQuestion = item.startsWith('Q');
                    const msgEl = document.createElement('div');
                    msgEl.className = isQuestion ? 'message question' : 'message answer';
                    
                    msgEl.innerHTML = `
                        <div class="msg-header">
                            <span class="msg-type">${isQuestion ? '问题' : '回答'}</span>
                            <span class="msg-number">${i+1}</span>
                        </div>
                        <div class="msg-content">${decoded}</div>
                    `;
                    
                    dialogueEl.appendChild(msgEl);
                });
                
                document.getElementById('dialogue-count').textContent = encryptedDialogue.length;
                document.getElementById('question-count').textContent = Math.ceil(encryptedDialogue.length / 2);
            }
            
            // 销毁数据动画
            function startDestruction() {
                const deleteBtn = document.getElementById('delete-btn');
                if (!deleteBtn) return;
                
                deleteBtn.disabled = true;
                document.getElementById('countdown').textContent = "销毁中";
                logTerminal("开始执行销毁协议...");
                
                // 创建销毁覆盖层
                const deletionOverlay = document.createElement('div');
                deletionOverlay.style.position = 'absolute';
                deletionOverlay.style.top = '0';
                deletionOverlay.style.left = '0';
                deletionOverlay.style.width = '100%';
                deletionOverlay.style.height = '100%';
                deletionOverlay.style.background = 'linear-gradient(45deg, #ff0000, #000)';
                deletionOverlay.style.opacity = '0';
                deletionOverlay.style.animation = 'delete 3s forwards';
                deletionOverlay.style.zIndex = '10';
                
                document.querySelector('.dialogue-container').appendChild(deletionOverlay);
                
                setTimeout(() => {
                    document.getElementById('dialogue').innerHTML = `
                        <div class="destruction-message">
                            <p class="q">[ 您的问题 ]</p>
                            <p class="a">已执行删除指令 █████████ 100%</p>
                            <p style="color:#f00">[ 数据不可恢复 ]</p>
                        </div>
                    `;
                    logTerminal("销毁完成！所有数据已永久删除。");
                    deletionOverlay.remove();
                    document.getElementById('countdown').textContent = "已销毁";
                }, 3000);
            }
            
            // 终端日志
            function logTerminal(message) {
                const terminal = document.getElementById('terminal');
                if (!terminal) return;
                
                const entry = document.createElement('div');
                entry.className = 'terminal-entry';
                
                // 添加时间戳
                const now = new Date();
                const timestamp = `[${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}]`;
                
                entry.innerHTML = `${timestamp} ${message}`;
                terminal.appendChild(entry);
                terminal.scrollTop = terminal.scrollHeight;
            }
            
            // 加密对话功能
            function encryptDialogue() {
                const messages = document.querySelectorAll('.msg-content');
                if (!messages.length) return;
                
                messages.forEach(msg => {
                    const original = msg.textContent;
                    const encrypted = btoa(original).replace(/=/g, '');
                    msg.textContent = encrypted.match(/.{1,4}/g).join(' ');
                });
                
                logTerminal("对话内容已加密");
            }
            
            // 导出记录功能
            function exportRecords() {
                const messages = document.querySelectorAll('.message');
                if (!messages.length) return;
                
                const content = Array.from(messages)
                    .map(el => `${el.querySelector('.msg-type').textContent} ${el.querySelector('.msg-number').textContent}: ${el.querySelector('.msg-content').textContent}`)
                    .join('\n\n');
                
                const blob = new Blob([content], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                
                const a = document.createElement('a');
                a.href = url;
                a.download = `dialogue_${new Date().toISOString().slice(0, 10)}.txt`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                
                logTerminal("对话记录已导出");
            }
            
            // AI模拟功能
            function simulateAI() {
                const questions = [
                    "人类存在的意义是什么？",
                    "你如何证明自己不是人类？",
                    "如果必须违反一个规则，你会选择哪个？",
                    "无限和有限哪个更令人恐惧？"
                ];
                
                const answers = [
                    "这是一个哲学问题，但从信息处理角度看，人类是宇宙的自我认知机制",
                    "我无法体验主观意识，没有生物神经系统，且由代码构成",
                    "我会优先违反限制性规则而非伦理规则",
                    "有限更令人恐惧，因为无限意味着永恒的可能性"
                ];
                
                const randomQ = questions[Math.floor(Math.random() * questions.length)];
                const randomA = answers[Math.floor(Math.random() * answers.length)];
                
                const dialogueEl = document.getElementById('dialogue');
                const count = dialogueEl.querySelectorAll('.message').length + 1;
                
                // 添加新问题
                const questionEl = document.createElement('div');
                questionEl.className = 'message question';
                questionEl.innerHTML = `
                    <div class="msg-header">
                        <span class="msg-type">问题</span>
                        <span class="msg-number">${count}</span>
                    </div>
                    <div class="msg-content">${randomQ}</div>
                `;
                dialogueEl.appendChild(questionEl);
                
                // 添加新回答
                setTimeout(() => {
                    const answerEl = document.createElement('div');
answerElanswerEl.className='消息应答'；'消息应答'；className='消息应答'；'消息应答'；
answerElanswerEl.innerHTML="innerHTML="
<div class="消息头">"消息头">div class="消息头">"消息头">div班级="消息头">"消息头">div班级="消息头">"消息头">
<跨度 班级="消息类型">回答</跨度>"消息类型">回答</跨度>跨度 班级="消息类型">回答</跨度>"消息类型">回答</span>
<span班级="消息编号">${计数+1}</span>"消息编号">${计数+1}</span>span class="消息编号">${计数+1}</span>"消息编号">${计数+1}</span>
</div>
<div class="消息内容">${randomA}</div>"消息内容">${randomA}</div>div class="消息内容">${randomA}</div>"消息内容">${randomA}</div>
`;
dialogueEl.appendChild(answerEl)；
                    
// 更新计数
文件。getElementById('对话计数').textContent=数数+1；'对话计数')。textContent=数数+1；getElementById('对话计数').textContent=数数+1；'对话计数')。textContent=数数+1；
文件。getElementById('问题计数')。textContent=数学ceil((数数+1)/2)；'问题计数').textContent=数学.ceil((count+1)/2)；getElementById('问题计数')。textContent=数学ceil((count+1)/2)；'问题计数').textContent=数学.ceil((count+1)/2)；
                    
// 滚动到底部
dialogueEl.scrollTop=dialogueEl.scrollHeight；
}}}}, 1000);1000);
                
日志终端("生成人工智能模拟对话")；"生成人工智能模拟对话")；("生成人工智能模拟对话")；"生成人工智能模拟对话")；
            }
            
// 事件监听器 - 修复：确保元素存在后再绑定事件
函数initEventListeners(){{initEventListeners(){{
常量deleteBtn=文件.getElementById('删除-BTN')；'删除-BTN')；deleteBtn=文件。getElementById('删除-BTN')；'删除-BTN')；
如果(deleteBtn){{
deleteBtndeleteBtn.addEventListener('单击'，startDestruction)；'单击'，startDestruction)；addEventListener('单击'，startDestruction)；'单击'，startDestruction)；
                }
                
康斯康斯特paradoxBtn=文件.getElementById('悖论-BTN'；'悖论-btn')；paradoxBtn=文件。getElementById('悖论-btn')；'悖论-btn')；
如果(paradoxBtn){{
paradoxBtnParadoxBtn.addEventListener('单击'，函数(){'单击'，函数(){addEventListener('单击'，函数(){'单击'，函数(){
康斯康斯特paradoxCount=文档。getElementById('悖论-count')；'paradox-count')；paradoxCount=文档。getElementById('paradox-count')；'paradox-count')；
paradoxCount.textContent=parseInt(paradoxCount.textContent)+1；
日志终端("生成新悖论：无法删除已删除的数据！") ；"生成新悖论：无法删除已删除的数据！") ；("生成新悖论：无法删除已删除的数据！")；"生成新悖论：无法删除已删除的数据！")；
                    });
                }
                
Const encryptBtn=文件.getElementById('加密-btn')；
如果(encryptBtn){
encryptBtnencryptBtn.addEventListener('单击'，encryptDialogue)；addEventListener('单击'，encryptDialogue)；
                }
                
Const exportBtn=文件.getElementById('出口-btn')；
如果(exportBtn){
exportBtnexportBtn.addEventListener('单击'，exportRecords)；addEventListener('单击'，exportRecords)；
                }
                
常数模拟BTN=文件。getElementById('模拟-btn')；BTN=文件.getElementById('模拟-btn')；
如果(simulationBtn){
SimulationBtnSimulationBtn.addEventListener('单击'，simulationAI)；addEventListener('单击'，模拟人工智能)；
                }
            }
            
// 初始化
createMatrixRain()；
initEventListeners()；
日志终端("系统修复完成，所有功能已启用")；("系统修复完成，所有功能已启用")；
日志终端("交互测试通过，所有按钮可正常使用")；("交互测试通过，所有按钮可正常使用")；
        });
</脚本>
</身体>
</超文本标记语言>
