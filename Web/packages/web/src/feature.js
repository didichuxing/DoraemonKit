import Console from './plugins/console/index'
import AppInfo from './plugins/app-info/index'
import Element from './plugins/element/index'
import scanCode from './plugins/scan-code/index.js'
import OneMachineWithMultipleControls from './plugins/one-machine-with-multiple-controls/index.js'
import Network from './plugins/network/index'
import Storage from './plugins/storage/index'
import DemoPlugin from './plugins/demo-plugin/index'
import DemoIndependPlugin from './plugins/demo-single-plugin/index'
import H5DoorPlugin from './plugins/h5-door/index'
import AlignRuler from './plugins/align-ruler/index'
import HelloWorld from './components/ToolHelloWorld'
import Resource from './plugins/resources/index'
import ApiMock from './plugins/api-mock/index'
import WebVitals from './plugins/web-vitals-time/index'
import WidgetBorder from './plugins/widget-border/index'


import {IndependPlugin, RouterPlugin} from '@dokit/web-core'

export const BasicFeatures = {
  title: '常用工具',
  list: [Console, AppInfo, Resource, Network, Storage, DemoPlugin, DemoIndependPlugin, H5DoorPlugin, WebVitals, Element, OneMachineWithMultipleControls, scanCode]
  // list: [Console, AppInfo, Resource, Network, Storage, H5DoorPlugin]
}

export const DokitFeatures = {
  title: '平台功能',
  list: [ApiMock]
}

export const UIFeatures = {
  title: '视觉功能',
  list: [AlignRuler, WidgetBorder]
  // list: [AlignRuler,
  // new RouterPlugin({
  //   nameZh: 'UI结构',
  //   name: 'view-selector',
  //   icon: 'https://pt-starimg.didistatic.com/static/starimg/img/XNViIWzG7N1618997548483.png',
  //   component: HelloWorld
  // })]
}
export const Features = [BasicFeatures, DokitFeatures, UIFeatures]
