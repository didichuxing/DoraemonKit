import { Store } from "../common/js/store";

const store = new Store({
  state: {
    showContainer: false,
    showHighlightElement:false,
    highlightElement:null,
    independPlugins: [],
    interfaceList:[],
    features: [],
    socketUrl:'',
    isHost:false,
    socketConnect: false,
    socketHistoryList:new Map(),
    mcClientWaitRequestQueue:[],
    mcHostWaitRequestQueue:[],
    mcHostWaitResponseQueue:[],
    mcClientWaitFetchRequestQueue:[],
    mcHostWaitFetchRequestQueue:[],
    mcHostWaitFetchResponseQueue:[],
    isNative:false,
    activeNodeKey: null,
  }
})

// 更新全局 Store 数据
export function updateGlobalData(key, value){
  store.state[key] = value
}

// 获取当前 Store 数据的状态
export function getGlobalData(){
  return store.state
}

export function toggleContainer(flag){
  if(flag){
    store.state.showContainer = flag;
  }else{
    store.state.showContainer = !store.state.showContainer;
  }
}

export function toggleHighlight(flag){
  if(flag){
    store.state.showHighlightElement = flag;
  }else{
    store.state.showHighlightElement = !store.state.showHighlightElement;
  }
}
export function toggleElement(element){
    store.state.highlightElement = element;
}

export function activeNodeTree(key){
  store.state.activeNodeKey = key;
}

export function addIndependPlugin(plugin){
  // Unique Container
  let index = store.state.independPlugins.findIndex(ele => {
    return ele.name === plugin.name
  })
  if (index > -1) return
  store.state.independPlugins.push(plugin)
}

export function removeIndependPlugin(name){
  let index = store.state.independPlugins.findIndex(ele => {
    return ele.name === name
  })
  if (index === -1) return
  store.state.independPlugins.splice(index, 1)
}

export default store