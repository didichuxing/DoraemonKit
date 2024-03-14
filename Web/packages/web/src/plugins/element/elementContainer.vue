<template>
  <div class="element-container">
    <div class="element-tab">
      <div
        @click="changeMode(0)"
        :class="`elemen-tab-item ${
          active === 0 ? 'elemen-tab-item-active' : ''
        }`"
      >
        视图树
      </div>
      <div
        @click="changeMode(1)"
        :class="`elemen-tab-item ${
          active === 1 ? 'elemen-tab-item-active' : ''
        }`"
      >
        元素属性
      </div>
    </div>
    <div class="tree-container" v-show="active === 0">
      <div class="real-time-switch">
        <div>实时更新</div>
        <input class="switch" type="checkbox" v-model="isRealTime" />
      </div>
      <ElementTree :node="node" />
    </div>
    <ElementDetails v-show="active === 1"></ElementDetails>
    <ElementSnippet />
  </div>
</template>

<script>
import ElementTree from './elementTree.vue';
import ElementDetails from './elementDetails.vue';
import ElementSnippet from './elementSnippet.vue';
// import MutationObserver from 'mutation-observer';
import { guid, $bus } from '../../assets/util';
import { debounce } from "../../assets/util";
import { toggleElement } from '@dokit/web-core';
export default {
  components: {
    ElementTree,
    ElementSnippet,
    ElementDetails,
  },
  data() {
    return {
      node: null, // 页面元素节点
      observer: null, // 页面元素监听实例
      isRealTime: null, // 是否实时更新节点显示
      config: {
        // 页面元素监听配置
        attributes: true,
        childList: true,
        characterData: true,
        subtree: true,
      },
      active: 0,
    };
  },
  created() {
    this.watchWindowSize = debounce(this.watchWindowSize, 300);
  },
  mounted() {
    window.addEventListener("resize", this.watchWindowSize);
    this.node = this.getNode(document.documentElement);
    this.observer = new MutationObserver((mutations) => {
      for (let i = 0; i < mutations.length; i++) {
        let mutation = mutations[i];
        if (this._isInDokit(mutation.target)) {
          continue;
        }
        this.onMutation(mutation);
      }
    });
    this.isRealTime =
      JSON.parse(localStorage.getItem("dokitElementRealTime")) ?? true;
    toggleElement(this.node.$view);
  },
  computed: {
    state() {
      return this.$store.state;
    },
    highlightElement() {
      return this.state.highlightElement;
    },
  },
  destroyed() {
    window.removeEventListener("resize", this.watchWindowSize);
    this.observer.disconnect();
  },
  watch: {
    isRealTime: {
      handler: function (newval) {
        if (newval) {
          this.node = this.getNode(document.documentElement);
          $bus.emit(this.node.key);
          localStorage.setItem("dokitElementRealTime", newval);
          this.observer.observe(document.documentElement, this.config);
        } else if (newval === false) {
          this.observer.disconnect();
          localStorage.setItem("dokitElementRealTime", newval);
        }
        console.log(this.node)
      },
      immediate: true,
    },
  },
  methods: {
    changeMode(e) {
      this.active = e;
    },
    getNode(elem) {
      if (this._isIgnoredElement(elem)) {
        return undefined;
      }

      let node = elem.__dokitForWeb_node || {};

      // basic node info
      node.$view = elem;
      node.nodeType = elem.nodeType;
      node.key = node.key || guid();
      node.nodeName = elem.nodeName;
      node.tagName = elem.tagName || "";
      node.textContent = "";
      if (
        node.nodeType == elem.TEXT_NODE ||
        node.nodeType == elem.DOCUMENT_TYPE_NODE
      ) {
        node.textContent = elem.textContent;
      }

      // boxStyle
      if (node.nodeType === elem.ELEMENT_NODE) {
        node.boxStyle = this.getBoxModelValue(elem);
      }

      // attrs
      node.id = elem.id || "";
      node.className = elem.className || "";
      node.attributes = [];
      if (elem.hasAttributes && elem.hasAttributes()) {
        for (let i = 0; i < elem.attributes.length; i++) {
          node.attributes.push({
            name: elem.attributes[i].name,
            value: elem.attributes[i].value || "",
          });
        }
      }

      // child nodes
      node.childNodes = [];
      if (elem.childNodes.length > 0) {
        for (let i = 0; i < elem.childNodes.length; i++) {
          let child = this.getNode(elem.childNodes[i]);
          if (!child) {
            continue;
          }
          node.childNodes.push(child);
        }
      }

      // save node to element for further actions
      elem.__dokitForWeb_node = node;
      return node;
    },
    _isIgnoredElement(elem) {
      // empty or line-break text
      if (elem.nodeType == elem.TEXT_NODE) {
        if (
          elem.textContent.replace(
            /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$|\n+/g,
            ""
          ) == ""
        ) {
          // trim
          return true;
        }
      }
      return false;
    },
    _isInDokit(elem) {
      let target = elem;
      while (target != undefined) {
        if (target.id == "dokit-root") {
          return true;
        }
        target = target.parentNode || undefined;
      }
      return false;
    },
    onMutation(mutation) {
      switch (mutation.type) {
        case "childList":
          if (mutation.removedNodes.length > 0) {
            this.onChildRemove(mutation);
          }
          if (mutation.addedNodes.length > 0) {
            this.onChildAdd(mutation);
          }
          break;
        case "attributes":
          this.onAttributesChange(mutation);
          break;
        case "characterData":
          this.onCharacterDataChange(mutation);
          break;
        default:
          break;
      }
    },
    onAttributesChange(mutation) {
      let node = mutation.target.__dokitForWeb_node;
      if (!node) {
        return;
      }
      if (mutation.target === this.highlightElement) {
        toggleElement(null);
        this.$nextTick(() => {
          toggleElement(mutation.target);
        });
      }
      node = this.getNode(mutation.target);
      $bus.emit(node.key + "refreshMy");
    },
    onCharacterDataChange(mutation) {
      let node = mutation.target.__dokitForWeb_node;
      if (!node) {
        return;
      }
      if (
        mutation.target === this.highlightElement ||
        mutation.target.parentNode === this.highlightElement
      ) {
        toggleElement(null);
        this.$nextTick(() => {
          toggleElement(mutation.target.parentNode);
        });
      }
      node = this.getNode(mutation.target);
      $bus.emit(node.key + "refreshMy");
    },
    onChildAdd(mutation) {
      let $parent = mutation.target,
        parentNode = $parent.__dokitForWeb_node;
      if (!parentNode) {
        return;
      }
      if ($parent === this.highlightElement) {
        toggleElement(null);
        this.$nextTick(() => {
          toggleElement($parent);
        });
      }
      this.getNode($parent);
      $bus.emit(parentNode.key + "refreshChild");
    },
    onChildRemove(mutation) {
      let $parent = mutation.target,
        parentNode = $parent.__dokitForWeb_node;
      if (!parentNode) {
        return;
      }
      for (let i = 0; i < mutation.removedNodes.length; i++) {
        let $target = mutation.removedNodes[i],
          key = $target?.__dokitForWeb_node?.key;
        if (!key) {
          continue;
        }
        if ($target === this.highlightElement) {
          toggleElement(null);
        }
        // remove view
        this.deleteNode(parentNode, key);
      }
      $bus.emit(parentNode.key + "refreshChild");
    },
    deleteNode(parentNode, nodeKey) {
      let deleteNodeIndex = parentNode.childNodes.findIndex(
        (item) => item.key === nodeKey
      );
      parentNode.childNodes.splice(deleteNodeIndex, 1);
    },
    getBoxModelValue(elem) {
      return {
        display: this.getStyle(elem, 'display'),  
        position: this.getStyle(elem, 'position'),
        top:this.getStyle(elem, 'top'),
        right:this.getStyle(elem, 'right'),
        bottom:this.getStyle(elem, 'bottom'),
        left:this.getStyle(elem, 'left'),
        marginTop: this.getStyle(elem, 'marginTop'),
        marginRight: this.getStyle(elem, 'marginRight'),
        marginBottom: this.getStyle(elem, 'marginBottom'),
        marginLeft: this.getStyle(elem, 'marginLeft'),
        borderTopWidth: this.getStyle(elem, 'borderTopWidth'),
        borderRightWidth: this.getStyle(elem, 'borderRightWidth'),
        borderBottomWidth: this.getStyle(elem, 'borderBottomWidth'),
        borderLeftWidth: this.getStyle(elem, 'borderLeftWidth'),
        paddingTop: this.getStyle(elem, 'paddingTop'),
        paddingRight: this.getStyle(elem, 'paddingRight'),
        paddingBottom: this.getStyle(elem, 'paddingBottom'),
        paddingLeft: this.getStyle(elem, 'paddingLeft'),
        contentWidth:
          (elem.offsetWidth -
          parseInt(this.getStyle(elem, 'paddingLeft')) -
          parseInt(this.getStyle(elem, 'paddingRight')) -
          parseInt(this.getStyle(elem, 'borderLeftWidth')) -
          parseInt(this.getStyle(elem, 'borderRightWidth'))),
        contentHeight:
          (elem.offsetHeight -
          parseInt(this.getStyle(elem, 'paddingTop')) -
          parseInt(this.getStyle(elem, 'paddingBottom')) -
          parseInt(this.getStyle(elem, 'borderTopWidth')) -
          parseInt(this.getStyle(elem, 'borderBottomWidth'))),
      };
    },
    getStyle(elem, attr) {
      let attrStyle = null;
      if (elem?.currentStyle) {
        attrStyle = elem.currentStyle[attr];
      } else {
        attrStyle = document.defaultView.getComputedStyle(elem, null)[attr];
      }
      if (attrStyle.indexOf("px") !== -1) {
        return /\d+/.exec(attrStyle)[0];
      } else {
        return attrStyle;
      }
    },
    watchWindowSize() {
      this.node = this.getNode(document.documentElement);
      this.oldElement = this.highlightElement
      toggleElement(null);
      this.$nextTick(() => {
        toggleElement(this.oldElement);
      });
    }
  },
};
</script>

<style lang="less" scope>
.element-container {
  position: relative;
  height: 100%;
  overflow: hidden;
  .tree-container {
    overflow-y: auto;
    height: calc(100% - 76px);
    .real-time-switch {
      display: flex;
      flex-direction: row;
      align-items: center;
      font-size: 18px;
      padding: 5px;
      .switch {
        appearance: none;
        -moz-appearance: button;
        -webkit-appearance: none;
      }
      .switch {
        position: relative;
        margin: 0;
        width: 40px;
        height: 24px;
        border: 1px solid #ebebf9;
        outline: 0;
        border-radius: 16px;
        box-sizing: border-box;
        background-color: #ebebf9;
        -webkit-transition: background-color 0.1s, border 0.1s;
        transition: background-color 0.1s, border 0.1s;
        margin-left: auto;
        &:before {
          content: " ";
          position: absolute;
          top: 0;
          left: 0;
          width: 38px;
          height: 22px;
          border-radius: 19px;
          background-color: #ebebf9;
          -webkit-transition: -webkit-transform 0.35s
            cubic-bezier(0.45, 1, 0.4, 1);
          transition: -webkit-transform 0.35s cubic-bezier(0.45, 1, 0.4, 1);
          transition: transform 0.35s cubic-bezier(0.45, 1, 0.4, 1);
        }

        &:after {
          content: " ";
          position: absolute;
          top: 0;
          left: 1px;
          width: 22px;
          height: 22px;
          border-radius: 15px;
          background-color: #ffffff;
          /*box-shadow: 0 1PX 3PX rgba(0, 0, 0, 0.4);*/
          -webkit-transition: -webkit-transform 0.35s
            cubic-bezier(0.4, 0.4, 0.25, 1.35);
          transition: -webkit-transform 0.35s cubic-bezier(0.4, 0.4, 0.25, 1.35);
          transition: transform 0.35s cubic-bezier(0.4, 0.4, 0.25, 1.35);
        }

        &:checked {
          background: rgb(69, 124, 190);
          border: solid 1px rgb(69, 124, 190);
        }

        &:checked:before {
          transform: scale(0);
        }

        &:checked:after {
          transform: translateX(15px);
        }
      }
    }
  }
  .element-tab {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    .elemen-tab-item {
      font-size: 18px;
      width: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 5px 10px;
      border-bottom: 1px #eee solid;
      &:first-child {
        border-right: 1px #eee solid;
      }
      &-active {
        border-bottom: 1px transparent solid;
        color: #457cbe;
      }
    }
  }
}
</style>