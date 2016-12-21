import $ from 'jquery';
import React from 'react';
import ReactDOM from 'react-dom';
import {ScAppBar} from './components/app-bar';
import {SideDrawer} from './components/side-drawer';
import {Footer} from './components/footer';
import {Game} from './components/game';
import {getQueryParam} from './util';
import {setupSideDrawerTransition} from './side-drawer-transition';
import {MENU_CATEGORIES, APP_NAME} from './constants';


$(() => {
    let gameUuid = getQueryParam('gameuuid');

    ReactDOM.render(
        <div>
            <SideDrawer pageName={APP_NAME} menuCategories={MENU_CATEGORIES}/>
            <ScAppBar appName={APP_NAME}/>
            <div className="mui--appbar-height"></div>
            <div id="content-wrapper">
                <Game httpService={$} gameUuid={gameUuid}/>
            </div>
            <Footer/>
        </div>,
        document.getElementById('game-page')
    );

    setupSideDrawerTransition();
});
