<template>
<div>
  <div class="mask" v-show="!showContainer"></div>
  <div v-for="rect in rect_info" v-bind:key="rect.id" :style="{position: 'fixed', left: rect.left+'px', top: rect.top+'px', width: rect.width+'px', height: rect.height+'px', border: '1px dashed #707d8b', zIndex: 4 }"></div>
  <div class="button-group">
    <div class="refresh" @click="refresh">刷新边框</div>
    <div class="cancel" @click="remove">取消边框</div>
  </div>
</div>
</template>
<script>
import { removeIndependPlugin } from "@dokit/web-core";
export default {
  data() {
    return {
      rect_info: [],
      scrollX: window.scrollX,
      scrollY: window.scrollY,
    }
  },

  computed: {
    state() {
      return this.$store.state;
    },
    showContainer() {
      return this.state.showContainer;
    },
    // displayRect(rect) {
    //   return {
    //     'position': 'fixed',
    //     'left': rect.left + 'px',
    //     'top': rect.top + 'px',
    //     'width': rect.width + 'px',
    //     'height': rect.height + 'px',
    //     'border': '1px dotted red'
    //   }
    // }
  },

  mounted() {
    this.getAllRect();
    window.addEventListener("scroll", this.handleScroll)
  },

  beforeUnmount() {
    window.removeEventListener("scroll", this.handleScroll)
  },
  
  methods: {

    getAllRect() {
      let elems = document.body.getElementsByTagName("*");
      // console.log(window.scrollX, window.scrollY);
      [].slice.call(elems).forEach((ele,idx) => {
        let rect = ele.getBoundingClientRect();
        // console.log(rect.top, window.scrollY);
        this.rect_info.push({id: idx, left: rect.left, top: rect.top, width: rect.width, height: rect.height});
      });
      // console.log(this.rect_info);
    },

    handleScroll() {
      this.rect_info.forEach(rect => {
        rect.left += (this.scrollX - window.scrollX);
        rect.top += (this.scrollY - window.scrollY);
        });
      this.scrollX = window.scrollX;
      this.scrollY = window.scrollY;
    },

    remove() {
      removeIndependPlugin("widget-border");
    },

    refresh() {
      this.getAllRect();
    }
  }
}
</script>
<style>
.button-group {
  display: flex;
  justify-content: space-around;
  width: 100%;
  position: fixed;
  bottom: 10%;
  z-index: 4;
}
.refresh, .cancel {
  width: 30%;
  height: 40px;
  margin: 0 auto;
  border-radius: 5px;
  background-color: antiquewhite;
  text-align: center;
  line-height: 40px;
}

.mask {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 3;
  background-color: #333333;
  opacity: 0.2;
}
</style>