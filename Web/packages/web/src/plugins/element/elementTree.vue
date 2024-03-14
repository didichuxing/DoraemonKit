<template>
  <div
    class="element-tree-container"
    :class="[canFold ? 'can-unfold' : '', unfold ? 'unfolded' : '']"
    v-if="isShow"
  >
    <!-- <div @click="unfoldDetail" v-html="displayDetailValue"></div> -->
    <div
      class="dkelm-l"
      v-if="node && node.nodeType === 1"
      :class="[
        isNullEndTag(node.tagName) || node.childNodes.length == 0
          ? 'dkelm-noc'
          : '',
        unfold ? 'dk-toggle' : '',
      ]"
    >
      <span class="dkelm-node"  :class="[isActived ? 'actived' : '']" @click="unfoldDetail">
        &lt;{{ node.tagName.toLowerCase() }}
        <i class="dkelm-k" v-if="node.className || node.attributes.length">
          <span v-for="(item, index) in node.attributes" :key="index">
            <span v-if="item.value !== ''">
              {{ " " + item.name }}=<i class="dkelm-v"> {{ item.value }} </i>
            </span>
            <span v-else>
              {{ " " + item.name }}
            </span>
          </span> </i
        >&gt;
      </span>
      <template v-if="canFold&&unfold">
        <div v-for="child in node.childNodes" :key="child.key">
          <ElementTree :node="child" :parentIsUnfold="unfold"></ElementTree>
        </div>
      </template>
      <span class="dkelm-node" :class="[isActived ? 'actived' : '']" @click="unfoldDetail" v-if="!isNullEndTag(node.tagName)"
        >&lt;/{{ node.tagName.toLowerCase() }}&gt;</span
      >
    </div>
    <template v-else-if="node && node.nodeType === 3 && node.textContent">
      {{ _trim(node.textContent) }}
    </template>
  </div>
</template>

<script>
import ElementTree from "./elementTree.vue";
import { $bus } from "../../assets/util";
import { activeNodeTree } from '@dokit/web-core';
export default {
  name: "ElementTree",
  components: {
    ElementTree,
  },
  data() {
    return {
      unfold: false,
      isShow: true,
    };
  },
  props: {
    node: Object,
    parentIsUnfold: Boolean,
  },
  watch: {
    unfold(val) {
      if (val) {
        $bus.on(this.node.key + "refreshChild", this.refreshSon);
      } else {
        $bus.off(this.node.key + "refreshChild", this.refreshSon);
      }
    },
    parentIsUnfold:{
      handler: function (val) {
        if(this.node?.key){
          if (val) {
            $bus.on(this.node.key + "refreshMy", this.refresh);
          } else {
            $bus.off(this.node.key + "refreshMy", this.refresh);
          }
        }
      },
      immediate: true,
    }
  },
  computed:{
    canFold() {
      return this.node?.childNodes.length > 0;
    },
    isActived() {
      console.log(this.activeNodeKey)
      return this.activeNodeKey === this.node?.key
    },
    state() {
      return this.$store.state;
    },
    activeNodeKey() {
      return this.state.activeNodeKey;
    },
  },
  created() {
    if (this?.node?.tagName === "HTML") {
      $bus.on(this.node.key, this.refresh);
    }
  },
  destroyed() {
    $bus.off(this.node.key, this.refresh);
    $bus.off(this.node.key, this.refreshSon);
  },
  methods: {
    refreshSon() {
      this.unfold = false;
      this.$nextTick(() => {
        this.unfold = true;
      });
    },
    refresh() {
      this.isShow = false;
      this.$nextTick(() => {
        this.isShow = true;
      });
    },
    isNullEndTag(tagName) {
      let names = ["br", "hr", "img", "input", "link", "meta"];
      tagName = tagName ? tagName.toLowerCase() : "";
      return names.indexOf(tagName) > -1 ? true : false;
    },
    unfoldDetail() {
      this.canFold&&(this.unfold = !this.unfold);
      activeNodeTree(this.node.key)
    },  
    _trim(str) {
      return str.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, "");
    },
  },
};
</script>

<style lang="less" scoped>
.element-tree-container {
  font-size: 16px;
  position: relative;
  &.can-unfold{
    &>.dkelm-l>.dkelm-node {
      cursor: pointer;
    }
  }
  .dkelm-l {
    padding-left: 8px;
    position: relative;
    word-wrap: break-word;
    line-height: 1;
    &::before {
      content: "";
      display: block;
      position: absolute;
      top: 6px;
      left: 3px;
      width: 0;
      height: 0;
      border: 3px solid transparent;
      border-left-color: #000;
    }
    &.dkelm-noc:before {
      display: none;
    }
    &.dk-toggle:before {
      display: block;
      top: 8px;
      left: 0;
      border-top-color: #000;
      border-left-color: transparent;
    }
  }
  .dkelm-node {
    color: #183691;
    &.actived{
      background: rgba(0, 0, 0, 0.1);
    }
  }
  .dkelm-k {
    color: #0086b3;
  }
  .dkelm-v {
    color: #905;
  }
}
</style>