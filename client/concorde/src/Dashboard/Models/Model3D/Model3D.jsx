import React from 'react'
import * as THREE from "three";

import { userService } from '../../../_services'
import DashboardItem from '../../DashboardItem';

class ModelCanvas extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      scene: null,
    }
    this.mountRef = React.createRef();
    this.mouse = new THREE.Vector2();
  }

  componentDidMount() {

    var scene = new THREE.Scene();
    this.props.onSceneCreated(scene);

    this.setState({
        scene: scene,
      });

    let width = 800; 
    let height = 600;

    var renderer = new THREE.WebGLRenderer();
    renderer.setSize(width, height);
    this.mountRef.current.appendChild( renderer.domElement );
    
    let camera = this.props.initScene(scene, width, height);

    if (this.props.mouseMove) {
      let mouse = this.mouse;
      let onDocumentMouseMove = function (event) {
        event.preventDefault();
        mouse.x = ( event.offsetX / width ) * 2 - 1;
        mouse.y = - ( event.offsetY / height ) * 2 + 1;
      }
      document.addEventListener( 'mousemove', onDocumentMouseMove, false );
    }

    let mouse = this.mouse;
    let mouseMove = this.props.mouseMove;

    var animate = function () {
      requestAnimationFrame( animate );
      renderer.render( scene, camera );
      if (mouseMove) {
        mouseMove(mouse);
      }
    };

    animate(this.mouse, this.props.mouseMove);

  }


  render() {
    return (
      <div ref={this.mountRef} style={{position: "relative"}}>

      </div>
    )
  }
}

class Model3D extends React.Component {

  constructor(props) {
    super(props);

    this.onConnected = this.onConnected.bind(this);
    this.setScene = this.setScene.bind(this);
}

onConnected(clientId) {
  this.getData(clientId);
}

getData(clientId) {
  userService.postRequest('client/' + clientId, {data: 'get', sort: 0, ascending: true})
  .then((result) => result.json())   
  .then((resp) => {
      this.props.loadScene(resp.table.data);
      this.setState(state => {
          return {
              ...state,
              clientId: clientId,
              headings: resp.table.headings,
              data: resp.table.data,
          }                    
      });
  });

}

  setScene(scene) {
    this.setState({
      scene: scene,
    });
  }

  render () {
      return (
        <DashboardItem 
          title={this.props.title} 
          model={this.props.model} 
          modelArg={this.props.modelArgs} 
          onConnected={this.onConnected} 
          onDashboardCommand={this.props.onDashboardCommand}
        >
          <ModelCanvas
            onSceneCreated={this.setScene}
            initScene={this.props.initScene || null}
            mouseMove={this.props.mouseMove || null}
          >
          </ModelCanvas>
        </DashboardItem>
      );
  }

}

export { Model3D };