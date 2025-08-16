import RetellWidget from './widget';

// Demo configuration - NO API KEY NEEDED!
const demoConfig = {
  agentId: 'agent_1dc973641c277176a5b941595d',
  position: 'bottom-right' as const,
  theme: 'purple' as const,
  proxyEndpoint: 'http://localhost:3001/api/create-web-call'
};

let currentWidget: RetellWidget | null = null;

// Initialize widget when DOM is ready
function initializeDemo() {
  // Hide loading message and show controls
  const loadingMessage = document.getElementById('loading-message');
  const demoControls = document.getElementById('demo-controls');
  
  if (loadingMessage) loadingMessage.style.display = 'none';
  if (demoControls) demoControls.style.display = 'block';

  // Create initial widget
  currentWidget = new RetellWidget(demoConfig);

  // Setup position controls
  const positionButtons = [
    { id: 'btn-bottom-right', position: 'bottom-right' },
    { id: 'btn-bottom-left', position: 'bottom-left' },
    { id: 'btn-top-right', position: 'top-right' },
    { id: 'btn-top-left', position: 'top-left' }
  ];

  positionButtons.forEach(({ id, position }) => {
    const button = document.getElementById(id);
    button?.addEventListener('click', () => {
      if (currentWidget) {
        currentWidget.destroy();
      }
      currentWidget = new RetellWidget({
        ...demoConfig,
        position: position as any
      });
    });
  });

  // Setup theme controls
  const themeButtons = [
    { id: 'btn-theme-purple', theme: 'purple' },
    { id: 'btn-theme-blue', theme: 'blue' },
    { id: 'btn-theme-green', theme: 'green' }
  ];

  themeButtons.forEach(({ id, theme }) => {
    const button = document.getElementById(id);
    button?.addEventListener('click', () => {
      if (currentWidget) {
        currentWidget.destroy();
      }
      currentWidget = new RetellWidget({
        ...demoConfig,
        theme: theme as any
      });
    });
  });

  // Toggle widget visibility
  const toggleButton = document.getElementById('btn-toggle');
  toggleButton?.addEventListener('click', () => {
    const widgetElement = document.getElementById('retell-widget');
    if (widgetElement) {
      if (widgetElement.style.display === 'none') {
        widgetElement.style.display = 'block';
      } else {
        widgetElement.style.display = 'none';
      }
    }
  });

  // Reset widget
  const resetButton = document.getElementById('btn-reset');
  resetButton?.addEventListener('click', () => {
    if (currentWidget) {
      currentWidget.destroy();
    }
    currentWidget = new RetellWidget(demoConfig);
  });
}

// Wait for DOM to be ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeDemo);
} else {
  initializeDemo();
}

// Export for potential use
export { currentWidget };
